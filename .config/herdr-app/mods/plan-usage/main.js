import { View, div, image, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { exec, home, layout, readTextFile, run, theme } from "herdr";

const REFRESH_MS = 3 * 60_000;
const BLOCK_ID = "usage";
const PADDING = 20;
const HEADER = 22;
const GAP = 8;
const BAR = 44;
const WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
const WINDOW_LABELS = { 300: "5-hour", 10080: "Weekly" };

const PROVIDERS = [
  { name: "Claude", icon: "icons/claude.svg", read: claudeWindows },
  { name: "Codex", icon: "icons/codex.svg", read: codexWindows },
  { name: "Grok", icon: "icons/grok.svg", tint: true, read: grokWindows },
];

const NEWEST_CODEX_ROLLOUT = 'find "$1" -name "*.jsonl" -type f -mtime -8 -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -1';
const LAST_MATCH = 'tail -c 1048576 "$1" 2>/dev/null | grep -F -- "$2" | tail -1';

async function sh(script, ...args) {
  const result = await exec("sh", ["-c", script, "sh", ...args], { timeout: 10_000 });

  return result.code === 0 ? result.stdout.trim() : "";
}

async function lastRecord(path, pattern) {
  const line = path ? await sh(LAST_MATCH, path, pattern) : "";

  return line ? JSON.parse(line) : null;
}

function usageWindow(label, used, resetsAt) {
  const resetMs = Number.isFinite(resetsAt) ? resetsAt * 1000 : null;
  const rolledOver = resetMs !== null && resetMs <= Date.now();

  return {
    label,
    used: rolledOver ? 0 : Math.max(0, Math.min(100, used)),
    resetMs: rolledOver ? null : resetMs,
  };
}

async function claudeWindows() {
  const text = await readTextFile(`${home()}/.cache/claude-code/rate-limits.json`);
  const limits = text ? JSON.parse(text) : null;

  return [["5-hour", limits?.five_hour], ["Weekly", limits?.seven_day]]
    .filter(([, entry]) => Number.isFinite(entry?.used_percentage))
    .map(([label, entry]) => usageWindow(label, entry.used_percentage, entry.resets_at));
}

async function codexWindows() {
  const rollout = await sh(NEWEST_CODEX_ROLLOUT, `${home()}/.codex/sessions`);
  const limits = (await lastRecord(rollout, '"rate_limits"'))?.payload?.rate_limits;

  return [limits?.primary, limits?.secondary]
    .filter((entry) => Number.isFinite(entry?.used_percent))
    .map((entry) => usageWindow(
      WINDOW_LABELS[entry.window_minutes] ?? `${Math.round(entry.window_minutes / 60)}h`,
      entry.used_percent,
      entry.resets_at,
    ));
}

async function grokWindows() {
  const record = await lastRecord(`${home()}/.grok/logs/unified.jsonl`, '"billing: fetched credits config"');
  const config = record?.ctx?.config;
  const period = config?.currentPeriod;
  if (!Number.isFinite(config?.creditUsagePercent)) return [];

  return [usageWindow(
    period?.type === "USAGE_PERIOD_TYPE_WEEKLY" ? "Weekly" : "Credits",
    config.creditUsagePercent,
    Date.parse(period?.end) / 1000,
  )];
}

function resetText(resetMs) {
  const minutes = Math.round((resetMs - Date.now()) / 60_000);
  if (minutes < 60) return `resets in ${Math.max(minutes, 1)}m`;

  const date = new Date(resetMs);
  const time = date.toTimeString().slice(0, 5);
  if (date.toDateString() === new Date().toDateString()) return `resets at ${time}`;

  return `resets on ${WEEKDAYS[date.getDay()]} ${time}`;
}

function blockHeight(providers) {
  const bars = providers.reduce((count, provider) => count + provider.windows.length, 0);

  return providers.length === 0
    ? 1
    : PADDING + providers.length * HEADER + (providers.length - 1) * GAP + bars * BAR;
}

export default class PlanUsage extends View {
  init(_props, cx) {
    this.providers = [];
    this.height = 0;
    this.refresh(cx);
    cx.timer.every(REFRESH_MS, (cx) => this.refresh(cx));
  }

  refresh(cx) {
    cx.spawn(async (cx) => {
      const providers = await Promise.all(PROVIDERS.map(async (provider) => ({
        ...provider,
        windows: await provider.read().catch(() => []),
      })));
      this.providers = providers.filter((provider) => provider.windows.length > 0);

      const height = blockHeight(this.providers);
      if (height !== this.height) {
        this.height = height;
        run("layout.resize", { id: BLOCK_ID, px: height });
      }

      cx.notify();
    });
  }

  bar(window, key, t) {
    const color = window.used >= 90 ? t.blocked : window.used >= 70 ? t.working : t.muted;

    return v_flex().id(key).h(BAR).justify_center().gap(3)
      .child(h_flex().justify_between().text_size(11.5)
        .child(div().text_color(t.muted).child(window.label))
        .child(div().font_medium().text_color(color === t.muted ? t.foreground : color).child(`${Math.round(window.used)}%`)))
      .child(div().h(5).w_full().rounded(3).bg(t.raised)
        .child(div().h(5).rounded(3).bg(color).w(`${Math.max(2, window.used)}%`)))
      .child(div().text_size(10.5).text_color(t.dim).truncate().child(window.resetMs === null ? "" : resetText(window.resetMs)));
  }

  render() {
    const t = theme();
    const sidebar = layout()?.children?.find((node) => node.id === "sidebar");
    const collapsed = (sidebar?.size?.px ?? Infinity) < 160;
    const icon = (provider) => provider.tint
      ? svg(provider.icon).size(13).flex_none().text_color(t.foreground)
      : image(provider.icon).w(13).h(13).flex_none();

    return v_flex().id("plan-usage").size_full().px(collapsed ? 4 : 14).py(PADDING / 2).gap(GAP)
      .bg(t.chrome).border_t(1).border_color(t.border).cursor_pointer()
      .on_click((_event, cx) => this.refresh(cx))
      .children(this.providers.map((provider) => collapsed
        ? v_flex().items_center().gap(2)
          .child(icon(provider))
          .children(provider.windows.map((window) => div().text_size(10).text_color(t.muted).child(`${Math.round(window.used)}%`)))
        : v_flex()
          .child(h_flex().h(HEADER).items_center().gap(6).text_size(11.5)
            .child(icon(provider))
            .child(div().font_medium().text_color(t.foreground).child(provider.name)))
          .children(provider.windows.map((window, index) => this.bar(window, `${provider.name}-${index}`, t)))));
  }
}
