pub const RTK_DATA_DIR: &str = "rtk";
pub const HISTORY_DB: &str = "history.db";
pub const CONFIG_TOML: &str = "config.toml";
#[cfg_attr(test, allow(dead_code))] // only reached via main()'s run_fallback path, invisible to the test-harness reachability graph
pub const FILTERS_TOML: &str = "filters.toml";
pub const TRUSTED_FILTERS_JSON: &str = "trusted_filters.json";
pub const DEFAULT_HISTORY_DAYS: i64 = 90;
