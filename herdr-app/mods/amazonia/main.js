// Amazônia: o rio ao entardecer do tema do Claude Code, animado com o
// movimento nativo do Herdr. A cena tem 200×124 "pixels" e cobre o bloco.
// Laços nativos (loop) fazem o sol respirar, as estrelas e os vaga-lumes
// piscarem e a água correr. Araras, canoa e boto atravessam com transition:
// um timer só marca o início de cada travessia, o resto roda sem script.

import { View, div, image } from "gpui-kit";
import { checking } from "herdr";
import { MOTES } from "./motes.js";

const W = 200;
const H = 124;
const IMG = "mods/amazonia/img";

const BIRDS_MS = 34000;
const CANOE_MS = 150000;
const BOTO_EVERY = 21000;

export default class Amazonia extends View {
  init(_props, cx) {
    this.size = { width: 0, height: 0 };
    this.birds = { n: 0, go: false };
    this.canoe = { n: 0, go: false };
    this.boto = false;
    this.started = false;
  }

  // Só depois do primeiro tamanho: antes disso nada é desenhado, e uma
  // travessia marcada sem desenho começaria já do outro lado.
  start(cx) {
    if (this.started || checking()) return;
    this.started = true;

    this.cross("birds", BIRDS_MS, cx);
    this.cross("canoe", CANOE_MS, cx);
    cx.timer.every(BOTO_EVERY, (cx) => {
      this.boto = true;
      cx.notify();
      cx.timer.after(1400, (cx) => {
        this.boto = false;
        cx.notify();
      });
    });
  }

  // Põe o bicho de volta na margem esquerda num salto (transição de 1 ms) e,
  // um instante depois, manda atravessar devagar. O id fica o mesmo: com um
  // id novo a travessia não anima.
  cross(key, ms, cx) {
    const start = (cx) => {
      this[key] = { n: this[key].n + 1, go: false };
      cx.notify();
      cx.timer.after(1500, (cx) => {
        this[key] = { ...this[key], go: true };
        cx.notify();
      });
    };
    start(cx);
    cx.timer.every(ms + 2500, start);
  }

  render(_cx) {
    const { width, height } = this.size;
    const s = Math.max(width / W, height / H) || 1;
    const ox = (width - W * s) / 2;
    const oy = (height - H * s) / 2;
    const u = (n) => n * s;
    const layer = (name) => image(`${IMG}/${name}.png`).absolute().w(u(W)).h(u(H));

    const motes = MOTES.map((m, i) => {
      const dot = Math.max(1, u(1));
      const el = div()
        .id(`mote-${i}`)
        .absolute()
        .left(ox + u(m.x) - u(2))
        .top(oy + u(m.y) - u(2))
        .w(u(5))
        .h(u(5))
        .flex()
        .items_center()
        .justify_center()
        .loop("opacity", { from: 0, to: 1, period: m.dur * 1000 })
        .loop("top", { from: oy + u(m.y) - u(2), to: oy + u(m.y - 6) - u(2), period: m.dur * 2000, easing: "linear" });
      return el
        .when(m.halo, (e) => e.bg(m.color + "30").rounded(u(3)))
        .child(div().w(dot).h(dot).bg(m.color));
    });

    return div()
      .id("amazonia")
      .relative()
      .size_full()
      .overflow_hidden()
      .bg("#04050b")
      .on_size_change((size, cx) => {
        this.size = size;
        cx.notify();
        if (size.width > 0) cx.timer.after(300, (cx) => this.start(cx));
      })
      .when(width > 0, (root) =>
        root
          .child(layer("base").left(ox).top(oy))
          .child(layer("stars").left(ox).top(oy).loop("opacity", { from: 0.35, to: 1, period: 4000 }))
          .child(layer("sun").left(ox).top(oy).loop("opacity", { from: 0.7, to: 1, period: 10000 }))
          .child(
            layer("water")
              .left(ox)
              .top(oy)
              .loop("left", { from: ox + u(3), to: ox - u(3), period: 9000 }),
          )
          // Boto: só aparece acima da linha d'água (y 92 da cena).
          .child(
            div()
              .absolute()
              .left(ox)
              .top(oy)
              .w(u(W))
              .h(u(92))
              .overflow_hidden()
              .child(
                layer("boto")
                  .id("boto")
                  .left(0)
                  .top(this.boto ? 0 : u(16))
                  .transition("top", { duration: 700, easing: this.boto ? "ease-out" : "ease-in" }),
              ),
          )
          .children(motes)
          .child(
            layer("canoe")
              .id("canoe")
              .top(oy)
              .left(ox + u(this.canoe.go ? 215 : -25))
              .transition("left", { duration: this.canoe.go ? CANOE_MS : 1, easing: "linear" }),
          )
          .child(
            div()
              .id("birds")
              .absolute()
              .w(u(W))
              .h(u(H))
              .top(oy)
              .left(ox + u(this.birds.go ? 230 : -30))
              .transition("left", { duration: this.birds.go ? BIRDS_MS : 1, easing: "linear" })
              .child(
                layer("birds")
                  .left(0)
                  .top(0)
                  .loop("top", { from: 0, to: u(3), period: 5000 }),
              ),
          ),
      );
  }
}
