#!/usr/bin/env python
# import-cc-switch.py — 把 win-dev-setup 的 CC Switch 配置写入 cc-switch.db
# 原理：providers.json 和 common_config.json 是 cc-switch.db 的导出，
#       直接写回数据库，CC Switch 打开即用，无需 GUI 手动添加。
# 用法: python scripts/import-cc-switch.py [cc-switch.db路径]
# 注意: 需先应用 .env（把 ${KEY} 替换成真实 key）
import sys, os, json, sqlite3

def load_db_path():
    """定位 cc-switch.db：命令行参数 > 默认位置"""
    if len(sys.argv) > 1:
        return sys.argv[1]
    home = os.path.expanduser('~')
    candidates = [
        os.path.join(home, '.cc-switch', 'cc-switch.db'),
    ]
    for c in candidates:
        if os.path.exists(c):
            return c
    return candidates[0]

def main():
    repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    # 优先读 .build/（setup.ps1 应用 .env 后生成，含真实 key），回退到 config/（占位符版）
    build = os.path.join(repo, '.build', 'cc-switch')
    config = os.path.join(repo, 'config', 'cc-switch')
    providers_path = os.path.join(build, 'providers.json') if os.path.exists(os.path.join(build, 'providers.json')) else os.path.join(config, 'providers.json')
    common_path = os.path.join(build, 'common_config.json') if os.path.exists(os.path.join(build, 'common_config.json')) else os.path.join(config, 'common_config.json')
    db_path = load_db_path()

    # 检查 .env 是否已应用（providers 里不应有 ${XXX} 占位符）
    with open(providers_path, encoding='utf-8') as f:
        providers = json.load(f)
    raw_providers = json.dumps(providers)
    if '${' in raw_providers:
        print('✗ providers.json 里还有 ${KEY} 占位符！请先运行 setup.ps1 或 apply-env.sh 应用 .env')
        sys.exit(1)

    with open(common_path, encoding='utf-8') as f:
        common_config = json.load(f)
    if '${' in json.dumps(common_config):
        print('✗ common_config.json 里还有 ${KEY} 占位符！请先运行 setup.ps1 或 apply-env.sh 应用 .env')
        sys.exit(1)

    # 确认 CC Switch 未运行（数据库被锁则写入失败）
    print(f'目标数据库: {db_path}')
    if not os.path.exists(db_path):
        print('✗ 未找到 cc-switch.db，请先安装并运行一次 CC Switch')
        sys.exit(1)

    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    # 1. 写入 providers（覆盖：清空后全量插入清单里的 provider）
    print('=== 写入 providers（覆盖）===')
    try:
        cur.execute("DELETE FROM providers")
        try:
            cur.execute("DELETE FROM sqlite_sequence WHERE name='providers'")  # 重置自增（表可能不存在）
        except sqlite3.Error:
            pass  # sqlite_sequence 不存在时忽略
    except sqlite3.OperationalError as e:
        print(f'✗ 数据库被锁定（CC Switch 正在运行？）: {e}')
        print('  请先关闭 CC Switch，再重新运行本脚本')
        conn.close()
        sys.exit(1)

    inserted = 0
    for p in providers:
        pid = p['id']
        cols = ['id','app_type','name','settings_config','website_url','category',
                'created_at','sort_index','notes','icon','icon_color','meta',
                'is_current','in_failover_queue','cost_multiplier',
                'limit_daily_usd','limit_monthly_usd','provider_type']
        vals = [p.get(c) for c in cols]
        cur.execute(
            f"INSERT INTO providers ({','.join(cols)}) VALUES ({','.join(['?']*len(cols))})",
            vals
        )
        inserted += 1
    print(f'  ✓ 已覆盖写入 {inserted} 个 provider')

    # 2. 写入 common_config
    print('=== 写入 common_config_claude ===')
    cur.execute("SELECT COUNT(*) FROM settings WHERE key='common_config_claude'")
    if cur.fetchone()[0] > 0:
        cur.execute("UPDATE settings SET value=? WHERE key='common_config_claude'",
                    (json.dumps(common_config, ensure_ascii=False),))
    else:
        cur.execute("INSERT INTO settings (key, value) VALUES ('common_config_claude', ?)",
                    (json.dumps(common_config, ensure_ascii=False),))
    print('  ✓ common_config 已写入')

    conn.commit()
    conn.close()
    print('\n✓ CC Switch 配置导入完成！打开 CC Switch 即可看到 providers 和通用配置。')

if __name__ == '__main__':
    main()
