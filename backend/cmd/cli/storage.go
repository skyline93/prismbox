package main

import (
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"strings"
	"text/tabwriter"
	"time"

	"github.com/urfave/cli/v2"

	"github.com/album/backend/internal/cli/remote"
)

func newStorageCommand() *cli.Command {
	return &cli.Command{
		Name:  "storage",
		Usage: "存储与存储池运维命令",
		Subcommands: []*cli.Command{
			newStoragePoolCommand(),
		},
	}
}

func newStoragePoolCommand() *cli.Command {
	return &cli.Command{
		Name:  "pool",
		Usage: "存储池相关操作",
		Subcommands: []*cli.Command{
			newStoragePoolListCommand(),
			newStoragePoolInfoCommand(),
			newStoragePoolAddCommand(),
			newStoragePoolUpdateCommand(),
			newStoragePoolEnableCommand(),
			newStoragePoolDisableCommand(),
			newStoragePoolRefreshCommand(),
			newStoragePoolReconcileCommand(),
			newStoragePoolUsageCommand(),
		},
	}
}

func newStoragePoolListCommand() *cli.Command {
	profile := commandProfile{requiresRemote: true}
	return &cli.Command{
		Name:  "list",
		Usage: "列出存储池列表",
		Flags: append(storageCommonFlags(),
			&cli.StringFlag{
				Name:  "type",
				Usage: "按类型过滤（local/s3/oss/cos/openlist）",
			},
			&cli.StringFlag{
				Name:  "status",
				Usage: "按状态过滤（active/disabled/maintenance）",
			},
		),
		Action: enforceProfile(profile, runStoragePoolList),
	}
}

func newStoragePoolInfoCommand() *cli.Command {
	profile := commandProfile{requiresRemote: true}
	return &cli.Command{
		Name:      "info",
		Usage:     "查看存储池详情",
		ArgsUsage: "<pool-uuid>",
		Flags:     storageCommonFlags(),
		Action:    enforceProfile(profile, runStoragePoolInfo),
	}
}

func newStoragePoolAddCommand() *cli.Command {
	profile := commandProfile{requiresRemote: true}
	return &cli.Command{
		Name:  "add",
		Usage: "新增存储池（写入 storage_pools 表）",
		Flags: append(storageCommonFlags(),
			&cli.StringFlag{Name: "name", Usage: "存储池名称", Required: true},
			&cli.StringFlag{Name: "type", Usage: "存储类型：local/openlist/s3/oss/cos", Required: true},
			&cli.StringFlag{Name: "local-path", Usage: "本地存储路径（type=local 必填）"},
			&cli.StringFlag{Name: "cloud-config", Usage: "云存储配置（JSON 字符串或 @path/to/file.json）"},
			&cli.StringFlag{Name: "max-size", Usage: "最大容量（如 1TB、500GB）", Required: true},
			&cli.IntFlag{Name: "priority", Usage: "优先级（数值越小优先级越高）", Value: 0},
			&cli.Float64Flag{Name: "auto-disable-threshold", Usage: "自动禁用阈值（0-1）", Value: 0.9},
			&cli.BoolFlag{Name: "enabled", Usage: "是否启用", Value: true},
			&cli.StringFlag{Name: "description", Usage: "描述"},
		),
		Action: enforceProfile(profile, runStoragePoolAdd),
	}
}

func newStoragePoolUpdateCommand() *cli.Command {
	profile := commandProfile{requiresRemote: true}
	return &cli.Command{
		Name:      "update",
		Usage:     "更新存储池配置（仅修改提供的字段）",
		ArgsUsage: "<pool-uuid>",
		Flags: append(storageCommonFlags(),
			&cli.StringFlag{Name: "name", Usage: "存储池名称"},
			&cli.StringFlag{Name: "local-path", Usage: "本地存储路径"},
			&cli.StringFlag{Name: "cloud-config", Usage: "云存储配置（JSON 字符串或 @path/to/file.json）"},
			&cli.StringFlag{Name: "max-size", Usage: "最大容量（如 1TB、500GB）"},
			&cli.IntFlag{Name: "priority", Usage: "优先级"},
			&cli.Float64Flag{Name: "auto-disable-threshold", Usage: "自动禁用阈值（0-1）"},
			&cli.BoolFlag{Name: "enabled", Usage: "是否启用"},
			&cli.StringFlag{Name: "description", Usage: "描述"},
		),
		Action: enforceProfile(profile, runStoragePoolUpdate),
	}
}

func newStoragePoolEnableCommand() *cli.Command {
	profile := commandProfile{requiresRemote: true}
	return &cli.Command{
		Name:      "enable",
		Usage:     "启用存储池写入",
		ArgsUsage: "<pool-uuid>",
		Flags:     storageCommonFlags(),
		Action:    enforceProfile(profile, runStoragePoolEnable),
	}
}

func newStoragePoolDisableCommand() *cli.Command {
	profile := commandProfile{requiresRemote: true}
	return &cli.Command{
		Name:      "disable",
		Usage:     "禁用存储池写入（维护/退役）",
		ArgsUsage: "<pool-uuid>",
		Flags: append(storageCommonFlags(),
			&cli.BoolFlag{Name: "force", Usage: "无需确认直接执行"},
		),
		Action: enforceProfile(profile, runStoragePoolDisable),
	}
}

func newStoragePoolRefreshCommand() *cli.Command {
	profile := commandProfile{requiresRemote: true}
	return &cli.Command{
		Name:  "refresh",
		Usage: "触发 PoolManager 缓存刷新",
		Flags: append(storageCommonFlags(),
			&cli.StringFlag{Name: "node", Usage: "指定节点（留空表示广播）"},
			&cli.BoolFlag{Name: "async", Usage: "异步执行，不等待结果"},
		),
		Action: enforceProfile(profile, runStoragePoolRefresh),
	}
}

func newStoragePoolReconcileCommand() *cli.Command {
	profile := commandProfile{requiresRemote: true}
	return &cli.Command{
		Name:  "reconcile",
		Usage: "触发一次对账（扫描磁盘并刷新 current_size）",
		Flags: append(storageCommonFlags(),
			&cli.StringFlag{Name: "pool", Usage: "指定池 UUID（为空则全部）"},
			&cli.BoolFlag{Name: "dry-run", Usage: "仅扫描不写入数据库"},
			&cli.IntFlag{Name: "parallel", Usage: "并行扫描线程数"},
		),
		Action: enforceProfile(profile, runStoragePoolReconcile),
	}
}

func newStoragePoolUsageCommand() *cli.Command {
	profile := commandProfile{requiresRemote: true}
	return &cli.Command{
		Name:  "usage",
		Usage: "查看存储池容量对比（数据库记录 vs 实际）",
		Flags: append(storageCommonFlags(),
			&cli.StringFlag{Name: "pool", Usage: "仅查看指定池"},
		),
		Action: enforceProfile(profile, runStoragePoolUsage),
	}
}

func storageCommonFlags() []cli.Flag {
	return []cli.Flag{
		&cli.StringFlag{
			Name:     "email",
			Usage:    "管理员邮箱",
			EnvVars:  []string{"ALBUM_CLI_EMAIL"},
			Required: true,
		},
		&cli.StringFlag{
			Name:     "password",
			Usage:    "管理员密码（建议通过 ALBUM_CLI_PASSWORD 提供）",
			EnvVars:  []string{"ALBUM_CLI_PASSWORD"},
			Required: true,
		},
		&cli.DurationFlag{
			Name:  "timeout",
			Usage: "接口超时时间",
			Value: 2 * time.Minute,
		},
		&cli.BoolFlag{
			Name:  "json",
			Usage: "以 JSON 格式输出",
		},
	}
}

func runStoragePoolList(c *cli.Context) error {
	client, err := buildStorageClient(c)
	if err != nil {
		return err
	}

	pools, err := client.ListStoragePools(c.Context, remote.StoragePoolListRequest{
		StorageType: c.String("type"),
		Status:      c.String("status"),
	})
	if err != nil {
		return err
	}

	if c.Bool("json") {
		return printJSON(pools)
	}

	if len(pools) == 0 {
		fmt.Println("暂无存储池")
		return nil
	}

	sort.Slice(pools, func(i, j int) bool {
		return pools[i].Priority < pools[j].Priority
	})

	w := tabwriter.NewWriter(os.Stdout, 0, 4, 2, ' ', 0)
	fmt.Fprintln(w, "UUID\tNAME\tTYPE\tENABLED\tSTATUS\tUSAGE\tPRIORITY\tLAST CHECKED")
	for _, pool := range pools {
		usage := "n/a"
		if pool.MaxSize > 0 {
			usage = fmt.Sprintf("%.1f%%", 100*float64(pool.CurrentSize)/float64(pool.MaxSize))
		}
		lastChecked := "-"
		if pool.LastCheckedAt != nil {
			lastChecked = pool.LastCheckedAt.Format(time.RFC3339)
		}
		fmt.Fprintf(w, "%s\t%s\t%s\t%t\t%s\t%s\t%d\t%s\n",
			pool.UUID, pool.Name, pool.StorageType, pool.Enabled, pool.Status, usage, pool.Priority, lastChecked)
	}
	return w.Flush()
}

func runStoragePoolInfo(c *cli.Context) error {
	uuid := strings.TrimSpace(c.Args().First())
	if uuid == "" {
		return fmt.Errorf("请提供存储池 UUID")
	}
	client, err := buildStorageClient(c)
	if err != nil {
		return err
	}

	pool, err := client.GetStoragePool(c.Context, uuid)
	if err != nil {
		return err
	}

	if c.Bool("json") {
		return printJSON(pool)
	}

	printStoragePoolDetails(pool)
	return nil
}

func runStoragePoolAdd(c *cli.Context) error {
	payload, err := buildStoragePoolPayload(c, true)
	if err != nil {
		return err
	}

	client, err := buildStorageClient(c)
	if err != nil {
		return err
	}

	result, err := client.CreateStoragePool(c.Context, payload)
	if err != nil {
		return err
	}

	if c.Bool("json") {
		return printJSON(result)
	}

	fmt.Printf("存储池创建成功：%s (%s)\n", result.Pool.Name, result.Pool.UUID)

	// Display refresh status
	if result.RefreshInfo != nil {
		if result.RefreshInfo.Success {
			fmt.Printf("✓ 存储池缓存已自动刷新：%s\n", result.RefreshInfo.Message)
			if result.RefreshInfo.TaskID != "" {
				fmt.Printf("  任务 ID: %s\n", result.RefreshInfo.TaskID)
			}
		} else {
			fmt.Printf("⚠ 自动刷新失败：%s\n", result.RefreshInfo.Error)
			fmt.Println("  请手动执行 `album storage pool refresh` 使存储池生效。")
		}
	}

	return nil
}

func runStoragePoolUpdate(c *cli.Context) error {
	uuid := strings.TrimSpace(c.Args().First())
	if uuid == "" {
		return fmt.Errorf("请提供存储池 UUID")
	}

	payload, err := buildStoragePoolPayload(c, false)
	if err != nil {
		return err
	}
	if len(payload) == 0 {
		return fmt.Errorf("请至少指定一个需要更新的字段")
	}

	client, err := buildStorageClient(c)
	if err != nil {
		return err
	}

	pool, err := client.UpdateStoragePool(c.Context, uuid, payload)
	if err != nil {
		return err
	}

	if c.Bool("json") {
		return printJSON(pool)
	}

	fmt.Printf("存储池已更新：%s (%s)\n", pool.Name, pool.UUID)
	return nil
}

func runStoragePoolEnable(c *cli.Context) error {
	return runStoragePoolStatusChange(c, true)
}

func runStoragePoolDisable(c *cli.Context) error {
	if !c.Bool("force") {
		fmt.Println("警告：禁用存储池会阻止新的写入，请确认已迁移或切换流量。")
	}
	return runStoragePoolStatusChange(c, false)
}

func runStoragePoolStatusChange(c *cli.Context, enable bool) error {
	uuid := strings.TrimSpace(c.Args().First())
	if uuid == "" {
		return fmt.Errorf("请提供存储池 UUID")
	}

	client, err := buildStorageClient(c)
	if err != nil {
		return err
	}

	if enable {
		if err := client.SetStoragePoolEnabled(c.Context, uuid, true); err != nil {
			return err
		}
		if c.Bool("json") {
			return printJSON(map[string]interface{}{"uuid": uuid, "enabled": true})
		}
		fmt.Printf("存储池 %s 已启用\n", uuid)
	} else {
		if err := client.SetStoragePoolEnabled(c.Context, uuid, false); err != nil {
			return err
		}
		if c.Bool("json") {
			return printJSON(map[string]interface{}{"uuid": uuid, "enabled": false})
		}
		fmt.Printf("存储池 %s 已禁用\n", uuid)
	}
	fmt.Println("可执行 `album storage pool refresh` 让所有实例立即感知状态变化。")
	return nil
}

func runStoragePoolRefresh(c *cli.Context) error {
	client, err := buildStorageClient(c)
	if err != nil {
		return err
	}

	resp, err := client.RefreshStoragePools(c.Context, remote.StoragePoolRefreshRequest{
		Node:  c.String("node"),
		Async: c.Bool("async"),
	})
	if err != nil {
		return err
	}

	if c.Bool("json") {
		return printJSON(resp)
	}

	fmt.Println(resp.Message)
	if resp.TaskID != "" {
		fmt.Printf("任务 ID: %s\n", resp.TaskID)
	}
	return nil
}

func runStoragePoolReconcile(c *cli.Context) error {
	client, err := buildStorageClient(c)
	if err != nil {
		return err
	}

	resp, err := client.ReconcileStoragePools(c.Context, remote.StoragePoolReconcileRequest{
		PoolUUID: c.String("pool"),
		DryRun:   c.Bool("dry-run"),
		Parallel: c.Int("parallel"),
	})
	if err != nil {
		return err
	}

	if c.Bool("json") {
		return printJSON(resp)
	}

	fmt.Println(resp.Message)
	if resp.TaskID != "" {
		fmt.Printf("任务 ID: %s\n", resp.TaskID)
	}
	return nil
}

func runStoragePoolUsage(c *cli.Context) error {
	client, err := buildStorageClient(c)
	if err != nil {
		return err
	}

	usage, err := client.GetStoragePoolUsage(c.Context, remote.StoragePoolUsageRequest{
		PoolUUID: c.String("pool"),
	})
	if err != nil {
		return err
	}

	if c.Bool("json") {
		return printJSON(usage)
	}

	if len(usage) == 0 {
		fmt.Println("暂无容量数据")
		return nil
	}

	w := tabwriter.NewWriter(os.Stdout, 0, 4, 2, ' ', 0)
	fmt.Fprintln(w, "UUID\tDB SIZE\tACTUAL SIZE\tDRIFT%\tLAST CHECKED")
	for _, u := range usage {
		drift := fmt.Sprintf("%.1f%%", u.DriftPercent)
		fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\n",
			u.UUID,
			formatBytes(u.DatabaseSize),
			formatBytes(u.ActualSize),
			drift,
			u.LastCheckedAt,
		)
	}
	return w.Flush()
}

func buildStorageClient(c *cli.Context) (*remote.Client, error) {
	client, err := remote.NewClient(remote.Config{
		BaseURL:    c.String("base-url"),
		SocketPath: c.String("socket-path"),
		Timeout:    c.Duration("timeout"),
	})
	if err != nil {
		return nil, fmt.Errorf("创建远程客户端失败: %w", err)
	}
	if err := client.LoginWithPassword(c.Context, c.String("email"), c.String("password")); err != nil {
		return nil, fmt.Errorf("登录失败: %w", err)
	}
	return client, nil
}

func buildStoragePoolPayload(c *cli.Context, requireAll bool) (map[string]interface{}, error) {
	payload := make(map[string]interface{})

	if requireAll || c.IsSet("name") {
		name := c.String("name")
		if requireAll && strings.TrimSpace(name) == "" {
			return nil, fmt.Errorf("--name 为必填项")
		}
		if strings.TrimSpace(name) != "" {
			payload["name"] = name
		}
	}

	if requireAll {
		storageType := strings.TrimSpace(c.String("type"))
		if storageType == "" {
			return nil, fmt.Errorf("--type 为必填项")
		}
		payload["storage_type"] = storageType
	} else if c.IsSet("type") {
		payload["storage_type"] = c.String("type")
	}

	if requireAll || c.IsSet("local-path") {
		localPath := strings.TrimSpace(c.String("local-path"))
		if requireAll && payload["storage_type"] == "local" && localPath == "" {
			return nil, fmt.Errorf("local 类型需要指定 --local-path")
		}
		if localPath != "" {
			payload["local_path"] = localPath
		}
	}

	if c.IsSet("cloud-config") || (requireAll && c.String("cloud-config") != "") {
		config, err := parseCloudConfig(c.String("cloud-config"))
		if err != nil {
			return nil, err
		}
		if config != nil {
			payload["cloud_config"] = config
		}
	}

	if requireAll || c.IsSet("max-size") {
		maxSize := strings.TrimSpace(c.String("max-size"))
		if requireAll && maxSize == "" {
			return nil, fmt.Errorf("--max-size 为必填项")
		}
		if maxSize != "" {
			value, err := parseSizeString(maxSize)
			if err != nil {
				return nil, err
			}
			payload["max_size"] = value
		}
	}

	if requireAll || c.IsSet("priority") {
		payload["priority"] = c.Int("priority")
	}

	if requireAll || c.IsSet("auto-disable-threshold") {
		threshold := c.Float64("auto-disable-threshold")
		payload["auto_disable_threshold"] = threshold
	}

	if requireAll || c.IsSet("enabled") {
		payload["enabled"] = c.Bool("enabled")
	}

	if requireAll || c.IsSet("description") {
		payload["description"] = c.String("description")
	}

	return payload, nil
}

func parseCloudConfig(value string) (map[string]interface{}, error) {
	value = strings.TrimSpace(value)
	if value == "" {
		return nil, nil
	}
	var data []byte
	var err error
	if strings.HasPrefix(value, "@") {
		data, err = os.ReadFile(strings.TrimPrefix(value, "@"))
		if err != nil {
			return nil, fmt.Errorf("读取 cloud-config 文件失败: %w", err)
		}
	} else {
		data = []byte(value)
	}
	config := make(map[string]interface{})
	if err := json.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("解析 cloud-config 失败: %w", err)
	}
	return config, nil
}

func parseSizeString(value string) (int64, error) {
	value = strings.TrimSpace(strings.ToUpper(value))
	if value == "" {
		return 0, fmt.Errorf("容量不能为空")
	}
	units := []struct {
		Suffix string
		Scale  int64
	}{
		{"TB", 1024 * 1024 * 1024 * 1024},
		{"GB", 1024 * 1024 * 1024},
		{"MB", 1024 * 1024},
		{"KB", 1024},
		{"B", 1},
	}
	for _, unit := range units {
		if strings.HasSuffix(value, unit.Suffix) {
			num := strings.TrimSuffix(value, unit.Suffix)
			num = strings.TrimSpace(num)
			var floatVal float64
			if _, err := fmt.Sscanf(num, "%f", &floatVal); err != nil {
				return 0, fmt.Errorf("无效的容量数值: %s", value)
			}
			return int64(floatVal * float64(unit.Scale)), nil
		}
	}
	// 无单位则尝试解析字节
	var bytes int64
	if _, err := fmt.Sscanf(value, "%d", &bytes); err == nil {
		return bytes, nil
	}
	return 0, fmt.Errorf("无法解析容量: %s", value)
}

func formatBytes(value int64) string {
	const (
		KB = 1024
		MB = KB * 1024
		GB = MB * 1024
		TB = GB * 1024
	)
	switch {
	case value >= TB:
		return fmt.Sprintf("%.2fTB", float64(value)/float64(TB))
	case value >= GB:
		return fmt.Sprintf("%.2fGB", float64(value)/float64(GB))
	case value >= MB:
		return fmt.Sprintf("%.2fMB", float64(value)/float64(MB))
	case value >= KB:
		return fmt.Sprintf("%.2fKB", float64(value)/float64(KB))
	default:
		return fmt.Sprintf("%dB", value)
	}
}

func printJSON(v interface{}) error {
	data, err := json.MarshalIndent(v, "", "  ")
	if err != nil {
		return err
	}
	fmt.Println(string(data))
	return nil
}

func printStoragePoolDetails(pool *remote.StoragePool) {
	fmt.Printf("UUID: %s\n", pool.UUID)
	fmt.Printf("名称: %s\n", pool.Name)
	fmt.Printf("类型: %s\n", pool.StorageType)
	fmt.Printf("启用: %t\n", pool.Enabled)
	fmt.Printf("状态: %s\n", pool.Status)
	fmt.Printf("优先级: %d\n", pool.Priority)
	fmt.Printf("最大容量: %s\n", formatBytes(pool.MaxSize))
	fmt.Printf("当前容量: %s\n", formatBytes(pool.CurrentSize))
	if pool.MaxSize > 0 {
		fmt.Printf("使用率: %.1f%%\n", 100*float64(pool.CurrentSize)/float64(pool.MaxSize))
	}
	if pool.LocalPath != "" {
		fmt.Printf("本地路径: %s\n", pool.LocalPath)
	}
	if pool.Description != "" {
		fmt.Printf("描述: %s\n", pool.Description)
	}
	if pool.LastCheckedAt != nil {
		fmt.Printf("最近检查: %s\n", pool.LastCheckedAt.Format(time.RFC3339))
	}
	if len(pool.CloudConfig) > 0 {
		fmt.Println("Cloud Config:")
		for k, v := range pool.CloudConfig {
			fmt.Printf("  - %s: %v\n", k, v)
		}
	}
}
