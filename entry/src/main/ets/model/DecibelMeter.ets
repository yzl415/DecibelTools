/**
 * 分贝测量服务：用 AudioCapturer 采集麦克风 PCM（单声道 16-bit/16kHz），
 * 在 readData 回调里实时计算 RMS → dB。不写文件、不录音、不上传。
 *
 * dB 计算：对每帧 Int16 PCM 求 RMS，相对满量程(32768)取 20*log10 得到 dBFS（≤0），
 * 再加一个经验偏移把它映射到接近声压级(SPL)的可读数值，并叠加用户校准值。
 */
import { audio } from '@kit.AudioKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 经验偏移：把 dBFS(-x) 抬到接近环境 SPL 的量程。不同机型麦克风灵敏度不同，用户可再校准。
const SPL_OFFSET: number = 90;

export class DecibelMeter {
  private capturer: audio.AudioCapturer | null = null;
  private running: boolean = false;
  private calibration: number = 0;
  // 回调：每帧算出一个 dB 值（已含校准）
  onDb: (db: number) => void = () => {};

  setCalibration(v: number): void {
    this.calibration = v;
  }

  isRunning(): boolean {
    return this.running;
  }

  /** 启动采集。已在运行则忽略。返回是否成功 */
  async start(): Promise<boolean> {
    if (this.running) {
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
    let db: number = dbfs + SPL_OFFSET + this.calibration;
    if (db < 0) {
      db = 0;
    }
    this.onDb(db);
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
