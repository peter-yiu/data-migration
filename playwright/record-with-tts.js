import { spawn } from 'child_process';
import { chromium } from '@playwright/test';
import googleTTS from 'google-tts-api';
import fs from 'fs/promises';
import path from 'path';

class AudioRecorder {
    constructor(options = {}) {
        this.options = {
            outputDir: 'videos',
            language: 'zh-CN',
            ttsSpeed: 1,
            ...options
        };

        this.audioQueue = [];
        this.isRecording = false;
    }

    async initialize() {
        await fs.mkdir(this.options.outputDir, { recursive: true });
        await fs.mkdir(path.join(this.options.outputDir, 'temp'), { recursive: true });
    }

    async textToSpeech(text) {
        const timestamp = Date.now();
        const audioFile = path.join(this.options.outputDir, 'temp', `speech-${timestamp}.mp3`);

        // 使用Google TTS API生成语音
        const url = googleTTS.getAudioUrl(text, {
            lang: this.options.language,
            slow: false,
            host: 'https://translate.google.com',
        });

        // 下载音频文件
        const response = await fetch(url);
        const buffer = await response.arrayBuffer();
        await fs.writeFile(audioFile, Buffer.from(buffer));

        return audioFile;
    }

    async startRecording() {
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const videoPath = path.join(this.options.outputDir, `recording-${timestamp}.mp4`);

        // FFmpeg命令，包含视频和音频录制
        const ffmpegArgs = [
            // 视频输入
            '-f', 'gdigrab',
            '-framerate', '30',
            '-i', 'desktop',
            // 系统声音
            '-f', 'dshow',
            '-i', 'audio=virtual-audio-capturer',
            // 麦克风
            '-f', 'dshow',
            '-i', 'audio=Microphone',
            // TTS音频输入（将在需要时动态添加）
            '-c:v', 'libx264',
            '-c:a', 'aac',
            '-filter_complex', '[1:a][2:a]amix=inputs=2:duration=first',
            videoPath
        ];

        this.ffmpeg = spawn('ffmpeg', ffmpegArgs);
        this.isRecording = true;

        // 启动浏览器
        this.browser = await chromium.launch({
            headless: false
        });

        const page = await this.browser.newPage();

        // 设置页面事件监听器
        await this.setupPageListeners(page);

        return page;
    }

    async speak(text) {
        if (!this.isRecording) return;

        try {
            const audioFile = await this.textToSpeech(text);
            this.audioQueue.push({
                text,
                file: audioFile,
                timestamp: Date.now()
            });

            // 播放音频文件（这里需要根据您的系统选择合适的播放方式）
            const player = spawn('powershell', [
                '-c',
                `(New-Object Media.SoundPlayer '${audioFile}').PlaySync()`
            ]);

            await new Promise((resolve) => {
                player.on('close', resolve);
            });

        } catch (error) {
            console.error('语音生成失败:', error);
        }
    }

    async setupPageListeners(page) {
        page.on('load', async () => {
            await this.speak(`页面加载完成：${page.url()}`);
        });

        page.on('click', async () => {
            await this.speak('用户点击');
        });

        page.on('dialog', async (dialog) => {
            await this.speak(`出现对话框：${dialog.message()}`);
        });
    }

    async stop() {
        this.isRecording = false;

        if (this.browser) {
            await this.browser.close();
        }
        if (this.ffmpeg) {
            this.ffmpeg.kill('SIGINT');
        }

        // 清理临时音频文件
        const tempDir = path.join(this.options.outputDir, 'temp');
        try {
            const files = await fs.readdir(tempDir);
            await Promise.all(
                files.map(file => fs.unlink(path.join(tempDir, file)))
            );
            await fs.rmdir(tempDir);
        } catch (error) {
            console.error('清理临时文件失败:', error);
        }
    }
}

// 使用示例
async function main() {
    const recorder = new AudioRecorder({
        language: 'zh-CN'
    });

    try {
        await recorder.initialize();
        const page = await recorder.startRecording();

        console.log('录制已开始，按 Ctrl+C 停止...');

        // 测试语音
        await recorder.speak('开始录制测试');
        await page.goto('https://example.com');
        await recorder.speak('正在访问示例网站');

        // 等待用户手动停止
        await new Promise((resolve) => {
            process.on('SIGINT', resolve);
        });

    } finally {
        await recorder.stop();
    }
}

main().catch(console.error);
