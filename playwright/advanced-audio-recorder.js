import { spawn } from 'child_process';
import { chromium } from '@playwright/test';
import googleTTS from 'google-tts-api';
import fs from 'fs/promises';
import path from 'path';
import ora from 'ora';
import chalk from 'chalk';

class AdvancedAudioRecorder {
    constructor(options = {}) {
        this.options = {
            outputDir: 'videos',
            language: 'zh-CN',
            audioSources: {
                systemAudio: true,
                microphone: true,
                tts: true
            },
            ttsOptions: {
                speed: 1,
                pitch: 1
            },
            ...options
        };

        this.audioQueue = [];
        this.isRecording = false;
        this.spinner = ora();
    }

    async initialize() {
        await fs.mkdir(this.options.outputDir, { recursive: true });
        await fs.mkdir(path.join(this.options.outputDir, 'temp'), { recursive: true });
    }

    async startRecording() {
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const videoPath = path.join(this.options.outputDir, `recording-${timestamp}.mp4`);

        // 构建FFmpeg命令
        const ffmpegArgs = this.buildFFmpegArgs(videoPath);

        this.ffmpeg = spawn('ffmpeg', ffmpegArgs);
        this.isRecording = true;

        // 设置FFmpeg错误处理
        this.ffmpeg.stderr.on('data', (data) => {
            const message = data.toString();
            if (message.includes('Error')) {
                console.error(chalk.red(`FFmpeg错误: ${message}`));
            }
        });

        // 启动浏览器
        this.browser = await chromium.launch({
            headless: false
        });

        const context = await this.browser.newContext();
        const page = await context.newPage();

        // 设置页面事件监听器
        await this.setupPageListeners(page);

        return page;
    }

    buildFFmpegArgs(outputPath) {
        const args = [
            // 视频输入
            '-f', 'gdigrab',
            '-framerate', '30',
            '-i', 'desktop'
        ];

        // 音频输入配置
        const audioInputs = [];
        if (this.options.audioSources.systemAudio) {
            args.push('-f', 'dshow', '-i', 'audio=virtual-audio-capturer');
            audioInputs.push('0:a');
        }
        if (this.options.audioSources.microphone) {
            args.push('-f', 'dshow', '-i', 'audio=Microphone');
            audioInputs.push('1:a');
        }

        // 添加编码器设置
        args.push(
            '-c:v', 'libx264',
            '-preset', 'ultrafast',
            '-c:a', 'aac'
        );

        // 如果有多个音频源，添加混音设置
        if (audioInputs.length > 1) {
            args.push(
                '-filter_complex',
                `${audioInputs.join('[2:a]')}amix=inputs=${audioInputs.length}:duration=first`
            );
        }

        args.push(outputPath);
        return args;
    }

    async speak(text) {
        if (!this.isRecording || !this.options.audioSources.tts) return;

        try {
            this.spinner.start(`生成语音: ${text}`);
            const audioFile = await this.textToSpeech(text);

            this.spinner.succeed(`语音已生成: ${text}`);

            // 播放语音
            await this.playAudio(audioFile);

            // 记录到队列
            this.audioQueue.push({
                text,
                file: audioFile,
                timestamp: Date.now()
            });

        } catch (error) {
            this.spinner.fail(`语音生成失败: ${error.message}`);
        }
    }

    async textToSpeech(text) {
        const timestamp = Date.now();
        const audioFile = path.join(this.options.outputDir, 'temp', `speech-${timestamp}.mp3`);

        const url = googleTTS.getAudioUrl(text, {
            lang: this.options.language,
            slow: false,
            speed: this.options.ttsOptions.speed,
            host: 'https://translate.google.com',
        });

        const response = await fetch(url);
        const buffer = await response.arrayBuffer();
        await fs.writeFile(audioFile, Buffer.from(buffer));

        return audioFile;
    }

    async playAudio(audioFile) {
        return new Promise((resolve, reject) => {
            const player = spawn('powershell', [
                '-c',
                `(New-Object Media.SoundPlayer '${audioFile}').PlaySync()`
            ]);

            player.on('close', resolve);
            player.on('error', reject);
        });
    }

    async setupPageListeners(page) {
        // 页面加载完成
        page.on('load', async () => {
            await this.speak(`页面加载完成：${page.url()}`);
        });

        // 用户点击
        page.on('click', async () => {
            await this.speak('检测到点击操作');
        });

        // 表单输入
        page.on('input', async () => {
            await this.speak('正在输入内容');
        });

        // 导航
        page.on('navigation', async () => {
            await this.speak('页面正在跳转');
        });

        // 对话框
        page.on('dialog', async (dialog) => {
            await this.speak(`出现对话框：${dialog.message()}`);
        });

        // 错误处理
        page.on('pageerror', async (error) => {
            await this.speak(`页面发生错误：${error.message}`);
        });
    }

    async stop() {
        this.isRecording = false;
        this.spinner.start('正在停止录制...');

        if (this.browser) {
            await this.browser.close();
        }
        if (this.ffmpeg) {
            this.ffmpeg.kill('SIGINT');
        }

        // 保存语音记录
        const audioLog = path.join(
            this.options.outputDir,
            `audio-log-${new Date().toISOString().replace(/[:.]/g, '-')}.json`
        );

        await fs.writeFile(
            audioLog,
            JSON.stringify(this.audioQueue, null, 2)
        );

        // 清理临时文件
        await this.cleanup();

        this.spinner.succeed('录制已完成');
        console.log(chalk.green(`\n语音记录已保存到: ${audioLog}`));
    }

    async cleanup() {
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
    const recorder = new AdvancedAudioRecorder({
        language: 'zh-CN',
        audioSources: {
            systemAudio: true,
            microphone: true,
            tts: true
        },
        ttsOptions: {
            speed: 1,
            pitch: 1
        }
    });

    try {
        await recorder.initialize();
        const page = await recorder.startRecording();

        console.log(chalk.green('\n录制已开始，按 Ctrl+C 停止...'));

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
