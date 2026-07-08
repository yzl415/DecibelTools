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
import { MOCK_HARDWARE } from './MockConfig';
import { DecibelLevelProcessor } from './DecibelLevelProcessor';

// 频谱条数量
const BANDS: number = 14;

export class DecibelMeter {
  private capturer: audio.AudioCapturer | null = null;
  private mockTimer: number = -1;      // 模拟模式定时器
  private mockBase: number = 55;       // 模拟模式当前基准 dB
  private running: boolean = false;
  private calibration: number = 0;
  private weighting: string = 'A';
  private response: string = 'FAST';
  private processor: DecibelLevelProcessor = new DecibelLevelProcessor();
  private levels: number[] = [];       // 频谱滚动缓冲（最近 BANDS 帧）
  // 回调：每帧算出一个 dB 值（已含校准 + 计权 + 时间平滑）
  onDb: (db: number) => void = () => {};

  configure(calibration: number, weighting: string, response: string): void {
    this.calibration = calibration;
    this.weighting = weighting;
    this.response = response;
    this.processor.configure(calibration, weighting, response);
    this.publishCurrentIfRunning();
  }

  setCalibration(v: number): void {
    this.configure(v, this.weighting, this.response);
  }

  setWeighting(w: string): void {
    this.configure(this.calibration, w, this.response);
  }

  setResponse(r: string): void {
    this.configure(this.calibration, this.weighting, r);
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
    this.processor.reset();
    this.processor.configure(this.calibration, this.weighting, this.response);
    this.levels = [];
    if (MOCK_HARDWARE) {
      this.startMock();
      this.running = true;
      return true;
    }
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
    this.publish(this.processor.processDbfs(dbfs));
  }

  /** 写入频谱缓冲后回调（真实/模拟共用） */
  private publish(db: number): void {
    this.levels.push(db);
    if (this.levels.length > 64) {
      this.levels = this.levels.slice(this.levels.length - 64);
    }
    this.onDb(db);
  }

  private publishCurrentIfRunning(): void {
    const current: number = this.processor.current();
    if (!this.running || current < 0) {
      return;
    }
    this.publish(current);
  }

  /** 模拟模式：生成在 35~85 dB 间缓慢游走的假数据 */
  private startMock(): void {
    this.mockBase = 55;
    this.mockTimer = setInterval(() => {
      this.mockBase += (Math.random() - 0.5) * 6;
      if (this.mockBase < 35) {
        this.mockBase = 35;
      } else if (this.mockBase > 85) {
        this.mockBase = 85;
      }
      this.publish(this.processor.processBaseSpl(this.mockBase + (Math.random() - 0.5) * 8));
    }, 100);
  }

  /** 停止并释放 */
  async stop(): Promise<void> {
    this.running = false;
    if (this.mockTimer !== -1) {
      clearInterval(this.mockTimer);
      this.mockTimer = -1;
    }
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
