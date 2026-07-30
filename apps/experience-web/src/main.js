/**
 * rebuild/0802 入口：仅验证说明带、锁触与占位布局。
 * 完整状态机实现将放在 src/flows/，契约对齐 background/06。
 */

const instructionText = document.getElementById("instruction-text");
const btnStart = document.getElementById("btn-start");
const letterbox = document.getElementById("letterbox");

btnStart?.addEventListener("click", () => {
  instructionText.textContent = "已点击开始。下一步：接入 segment 流程与视频页。";
  letterbox.innerHTML =
    '<p class="stage__placeholder">G0 完成。请在此格接入奉天门停驻点（S01）。</p>';
});

// 除说明带外锁死误触：document 级捕获，非说明带区域不响应
document.addEventListener(
  "click",
  (e) => {
    const band = document.getElementById("instruction-band");
    if (band && !band.contains(e.target)) {
      e.stopPropagation();
    }
  },
  true
);
