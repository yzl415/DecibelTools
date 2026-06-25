/**
 * 分贝测量服务：用 AudioCapturer 采集麦克风 PCM（单声道 16-bit/16kHz），
 * 在 readData 回调里实时计算 RMS → dB。不写文件、不录音、不上传。
 *
 * dB 计算：对每帧 Int16 PCM 求 RMS，相对满量程(32768)取 20*log10 得到 dBFS（≤0），
 * 再加经验偏移映射到接近声压级(SPL)的可读数值，叠加用户校准值。
 *
 * 计权说明：真正的 dB(A)/dB(C) 需对信号做倍频程滤波（FFT），此处用一个近似偏置
 * 区分两档（A 略低于 C），以贴合常见读数习惯，并非严格计量级声学加权。
 *
 * 时间计权：FAST（τ≈125ms）/ SLOW（τ≈1000ms），用一阶指数平滑模拟。
 */
import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 经验偏移：把 dBFS(-x) 抬到接近环境 SPL 的量程。不同机型麦克风灵敏度不同，用户可再校准。
const SPL_OFFSET: number = 90;
// A/C 近似偏置：A 计权对低频抑制更强，整体读数略低
const WEIGHT_A_BIAS: number = -1.5;
const WEIGHT_C_BIAS: number = 0;
// 频谱条数量
const BANDS: number = 14;

export class DecibelMeter {
  private capturer: audio.AudioCapturer | null = null;
  private running: boolean = false;
  private calibration: number = 0;
  private weighting: string = 'A';
  private response: string = 'FAST';
  private smoothed: number = -1;       // 时间计权后的平滑值
  private levels: number[] = [];       // 频谱滚动缓冲（最近 BANDS 帧）
  // 回调：每帧算出一个 dB 值（已含校准 + 计权 + 时间平滑）
  onDb: (db: number) => void = () => {};

  setCalibration(v: number): void {
    this.calibration = v;
  }

  setWeighting(w: string): void {
    this.weighting = w;
  }

  setResponse(r: string): void {
    this.response = r;
  }

  isRunning(): boolean {
    return this.running;
  }

  /** 取最近的频谱条（归一化 0~1，长度 BANDS），用于波形显示 */
  getSpectrum(): number[] {
    const out: number[] = [];
    for (let i = 0; i < BANDS; i++) {
      const idx: number = this.levels.length - BANDS + i;
      const v: number = idx >= 0 ? this.levels[idx] : 0;
      // 30~110 dB 映射到 0~1
      let n: number = (v - 30) / 80;
      if (n < 0.06) {
        n = 0.06;
      } else if (n > 1) {
        n = 1;
      }
      out.push(n);
    }
    return out;
  }

  /** 启动采集。已在运行则忽略。返回是否成功 */
  async start(): Promise<boolean> {
    if (this.running) {
      return true;
    }
    this.smoothed = -1;
    this.levels = [];
    const streamInfo: audio.AudioStreamInfo = {
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
      channels: audio.AudioChannel.CHANNEL_1,
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
    };
    const capturerInfo: audio.AudioCapturerInfo = {
      source: audio.SourceType.SOURCE_TYPE_MIC,
      capturerFlags: 0
    };
    const options: audio.AudioCapturerOptions = {
      streamInfo: streamInfo,
      capturerInfo: capturerInfo
    };
    try {
      this.capturer = await audio.createAudioCapturer(options);
      this.capturer.on('readData', (buffer: ArrayBuffer) => {
        this.handleBuffer(buffer);
      });
      await this.capturer.start();
      this.running = true;
      return true;
    } catch (e) {
      const err = e as BusinessError;
      console.error(`DecibelMeter start failed: ${err.code} ${err.message}`);
      await this.release();
      return false;
    }
  }

  /** 把一帧 PCM 转成 dB 并回调 */
  private handleBuffer(buffer: ArrayBuffer): void {
    const samples: Int16Array = new Int16Array(buffer);
    const len: number = samples.length;
    if (len === 0) {
      return;
    }
    let sumSq: number = 0;
    for (let i = 0; i < len; i++) {
      const s: number = samples[i];
      sumSq += s * s;
    }
    const rms: number = Math.sqrt(sumSq / len);
    if (rms < 1) {
      return; // 静默帧，跳过避免 -Infinity
    }
    const dbfs: number = 20 * Math.log10(rms / 32768);   // ≤ 0
    const bias: number = this.weighting === 'C' ? WEIGHT_C_BIAS : WEIGHT_A_BIAS;
    let raw: number = dbfs + SPL_OFFSET + this.calibration + bias;
    if (raw < 0) {
      raw = 0;
    }
    // 时间计权（一阶指数平滑）：FAST 反应快，SLOW 平缓
    const alpha: number = this.response === 'SLOW' ? 0.12 : 0.45;
    if (this.smoothed < 0) {
      this.smoothed = raw;
    } else {
      this.smoothed = this.smoothed + alpha * (raw - this.smoothed);
    }
    // 频谱缓冲：存瞬时值，保留尾部
    this.levels.push(raw);
    if (this.levels.length > 64) {
      this.levels = this.levels.slice(this.levels.length - 64);
    }
    this.onDb(this.smoothed);
  }

  /** 停止并释放 */
  async stop(): Promise<void> {
    this.running = false;
    if (this.capturer === null) {
      return;
    }
    try {
      await this.capturer.stop();
    } catch (e) {
      const err = e as BusinessError;
      console.error(`DecibelMeter stop failed: ${err.code} ${err.message}`);
    }
    await this.release();
  }

  private async release(): Promise<void> {
    if (this.capturer === null) {
      return;
    }
    try {
      this.capturer.off('readData');
      await this.capturer.release();
    } catch (e) {
      const err = e as BusinessError;
      console.error(`DecibelMeter release failed: ${err.code} ${err.message}`);
    }
    this.capturer = null;
  }
}
