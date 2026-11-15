import { View, div, image, svg } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { appHome, exec, layout, nextCommand, theme } from "herdr";
import { mkdir, readdir, unlink } from "fs/promises";

const SCRIPT = `
function run(args) {
  const spotify = Application("com.spotify.client");
  if (!spotify.running()) return JSON.stringify({ running: false });

  const action = args[0];
  if (action === "play") spotify.play();
  else if (action === "pause") spotify.pause();
  else if (action === "previous") spotify.previousTrack();
  else if (action === "next") spotify.nextTrack();
  else if (action === "shuffle") spotify.shuffling = !spotify.shuffling();
  else if (action === "repeat") spotify.repeating = !spotify.repeating();
  else if (action !== "read") throw new Error("Unknown Spotify action");

  const state = spotify.playerState();
  if (state === "stopped") return JSON.stringify({ running: true, state });

  const track = spotify.currentTrack;
  return JSON.stringify({
    running: true,
    state,
    title: track.name(),
    artist: track.artist(),
    artwork: track.artworkUrl(),
    shuffle: spotify.shuffling(),
    repeat: spotify.repeating(),
    canShuffle: spotify.shufflingEnabled(),
    canRepeat: spotify.repeatingEnabled()
  });
}
`;

async function player(action = "read") {
  const result = await exec("/usr/bin/osascript", ["-l", "JavaScript", "-e", SCRIPT, action], { timeout: 15_000 });
  if (result.code !== 0) throw new Error(result.stderr.trim() || "Spotify did not respond");

  return JSON.parse(result.stdout);
}

async function openSpotify() {
  const result = await exec("/usr/bin/open", ["-b", "com.spotify.client"], { timeout: 5_000 });
  if (result.code !== 0) throw new Error(result.stderr.trim() || "Spotify could not open");
}

async function downloadArtwork(url) {
  if (!url || !url.startsWith("https://")) return null;

  const directory = `${appHome()}/data/spotify-player`;
  await mkdir(directory, { recursive: true });

  const name = `cover-${Date.now()}.img`;
  const result = await exec("/usr/bin/curl", [
    "--fail", "--silent", "--show-error", "--location",
    "--proto", "=https", "--proto-redir", "=https",
    "--max-time", "8", "--output", `${directory}/${name}`, url,
  ], { timeout: 10_000 });
  if (result.code !== 0) {
    await unlink(`${directory}/${name}`).catch(() => {});
    return null;
  }

  for (const old of await readdir(directory)) {
    if (/^cover-\d+\.img$/.test(old) && old !== name) {
      await unlink(`${directory}/${old}`).catch(() => {});
    }
  }

  return `data/spotify-player/${name}`;
}

const ICONS = "mods/spotify-player";

function sidebarWidth() {
  return layout()?.children?.find((node) => node.id === "sidebar")?.size?.px ?? Infinity;
}

export default class SpotifyPlayer extends View {
  init(_props, cx) {
    this.track = null;
    this.error = "";
    this.art = null;
    this.artUrl = "";
    this.artRetryAt = 0;
    this.reading = false;
    this.busy = false;
    this.revision = 0;
    this.nextRead = 0;
    this.refresh(cx);
    cx.timer.every(2_000, (cx) => this.refresh(cx));
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        if (["play", "pause", "previous", "next", "shuffle", "repeat", "open"].includes(command)) this.act(command, cx);
        else if (command === "refresh") this.refresh(cx, true);
      }
    });
  }

  refresh(cx, force = false) {
    if (this.reading || this.busy || (!force && Date.now() < this.nextRead)) return;

    this.reading = true;
    const revision = this.revision;
    cx.spawn(async (cx) => {
      try {
        const track = await player();
        if (revision !== this.revision) return;

        const changed = JSON.stringify(track) !== JSON.stringify(this.track) || this.error;
        this.track = track;
        this.error = "";
        this.nextRead = Date.now() + (track.state === "playing" ? 2_000 : 10_000);
        if (this.artUrl !== (track.artwork || "")) {
          this.artUrl = track.artwork || "";
          this.art = null;
          this.artRetryAt = 0;
        }
        if (changed) cx.notify();

        if (this.artUrl && !this.art && Date.now() >= this.artRetryAt) {
          this.artRetryAt = Date.now() + 30_000;
          const url = this.artUrl;
          const art = await downloadArtwork(url).catch(() => null);
          if (this.artUrl === url && art) {
            this.art = art;
            cx.notify();
          }
        }
      } catch (error) {
        if (revision !== this.revision) return;

        const message = String(error.message || error);
        if (this.error !== message) {
          this.error = message;
          cx.notify();
        }
        this.nextRead = Date.now() + 30_000;
      } finally {
        this.reading = false;
        if (revision !== this.revision) this.nextRead = 0;
      }
    });
  }

  act(action, cx) {
    if (this.busy) return;
    if (action !== "open" && (!this.track?.running || this.error)) return;

    this.busy = true;
    this.revision += 1;
    cx.notify();
    cx.spawn(async (cx) => {
      try {
        if (action === "open") await openSpotify();
        else await player(action);

        this.error = "";
      } catch (error) {
        this.error = String(error.message || error);
      } finally {
        this.busy = false;
        this.nextRead = Date.now() + (this.error ? 30_000 : 0);
        cx.notify();
        if (!this.error) cx.timer.after(400, (cx) => this.refresh(cx, true));
      }
    });
  }

  button(action, label, enabled, active = false) {
    const t = theme();
    const playback = action === "play" || action === "pause";
    const live = enabled && !this.busy;

    return div().id(`spotify-${action}`).size(sidebarWidth() < 224 ? 24 : 30).rounded_full()
      .flex().items_center().justify_center().tooltip(label)
      .text_color(live ? (active ? "#1DB954" : t.foreground) : t.dim)
      .when(active, (el) => el.bg(t.raised))
      .when(playback && enabled, (el) => el.bg(t.foreground).text_color(t.chrome))
      .when(live, (el) => el.cursor_pointer()
        .hover((el) => el.bg(playback ? t.muted : t.hover))
        .on_click((_event, cx) => this.act(action, cx)))
      .child(svg(`${ICONS}/${action === "open" ? "play" : action}.svg`).size(16));
  }

  render(cx) {
    const t = theme();
    const width = sidebarWidth();
    const collapsed = width < 160;
    const playing = this.track?.state === "playing";
    const main = !this.track?.running ? "open" : playing ? "pause" : "play";
    const enabled = Boolean(this.track?.running && this.track?.title && !this.error);
    const denied = /-1743|not authorized|not permitted/i.test(this.error);
    const title = this.error ? (denied ? "Spotify の操作許可が必要です" : "Spotify を取得できません")
      : !this.track ? "Spotify を確認中…"
      : !this.track.running ? "Spotify を開く"
      : this.track.title || "再生中の曲はありません";
    const subtitle = this.error ? "クリックして再試行"
      : this.track?.artist || "Spotify";
    const cover = this.art && !this.error
      ? image(this.art).size(36).rounded(4).flex_none()
      : div().size(36).rounded(4).bg(t.raised).flex_none().flex().items_center().justify_center()
        .child(svg(`${ICONS}/music.svg`).size(18).text_color(t.muted));

    return v_flex().id("spotify-player").size_full().bg(t.chrome).border_t(1).border_color(t.border)
      .px(collapsed ? 0 : 12).py(10).gap(8).justify_center()
      .when(!collapsed, (el) => el.child(h_flex().id("spotify-track").gap(10).items_center().cursor_pointer()
        .tooltip(this.error || [title, this.track?.artist].filter(Boolean).join(" · "))
        .on_click((_event, cx) => this.error ? this.refresh(cx, true) : this.act("open", cx))
        .child(cover)
        .child(v_flex().flex_1().min_w(0).gap(2)
          .child(div().text_size(12.5).font_medium().text_color(t.foreground).truncate().child(title))
          .child(div().text_size(11.5).text_color(t.muted).truncate().child(subtitle)))))
      .child(h_flex().gap(width < 224 ? 2 : 12).justify_center().items_center()
        .when(!collapsed, (el) => el
          .child(this.button("shuffle", `シャッフル: ${this.track?.shuffle ? "オン" : "オフ"}`,
            enabled && this.track.canShuffle, this.track?.shuffle))
          .child(this.button("previous", "前の曲", enabled)))
        .child(collapsed && this.error
          ? div().id("spotify-retry").size(30).flex().items_center().justify_center().cursor_pointer()
            .tooltip(title).on_click((_event, cx) => this.refresh(cx, true)).child("!")
          : this.button(main, { open: "Spotify を開く", pause: "一時停止", play: "再生" }[main],
            enabled || (this.track?.running === false && !this.error)))
        .when(!collapsed, (el) => el
          .child(this.button("next", "次の曲", enabled))
          .child(this.button("repeat", `リピート: ${this.track?.repeat ? "オン" : "オフ"}`,
            enabled && this.track.canRepeat, this.track?.repeat))));
  }
}
