import { spawn } from 'child_process';
import { chromium } from '@playwright/test';
import ora from 'ora';
import chalk from 'chalk';
import fs from 'fs/promises';

async function recordBrowserAdvanced(options = {}) {
    const {
        url = 'https://example.com',
        width = 1280,
        height = 720,
        framerate = 30,
        quality = 18, // 0-51，越低质量越好
        outputDir = 'videos'
    } = options;

    const spinner = ora('准备录制环境...').start();

    try {
        // 创建输出目录
        await fs.mkdir(outputDir, { recursive: true });

        // 准备文件名
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const videoPath = `${outputDir}/recording-${timestamp}.mp4`;

        // 启动浏览器
        spinner.text = '启动浏览器...';
        const browser = await chromium.launch({
            headless: false,
            args: [
                `--window-size=${width},${height}`,
                '--window-position=0,0'
            ]
        });

        const context = await browser.newContext({
            viewport: { width, height }
        });

        const page = await context.newPage();

        // 设置录制参数
        const ffmpegArgs = [
            '-f', 'gdigrab',
            '-framerate', framerate.toString(),
            '-offset_x', '0',
            '-offset_y', '0',
            '-video_size', `${width}x${height}`,
            '-i', 'desktop',
            '-c:v', 'libx264',
            '-preset', 'ultrafast',
            '-crf', quality.toString(),
            videoPath
        ];

        // 启动录制
        spinner.text = '启动录制...';
        const ffmpeg = spawn('ffmpeg', ffmpegArgs);

        // 错误处理
        ffmpeg.stderr.on('data', (data) => {
            const message = data.toString();
            if (message.includes('frame=')) {
                // 更新进度信息
                spinner.text = `录制中: ${message.trim()}`;
            } else if (message.includes('Error')) {
                console.error(chalk.red(`FFmpeg错误: ${message}`));
            }
        });

        // 导航到目标网站
        spinner.text = '加载页面...';
        await page.goto(url);

        spinner.succeed('录制已开始');
        console.log(chalk.green('\n正在录制浏览器窗口...'));
        console.log(chalk.yellow('按 Ctrl+C 停止录制\n'));

        // 监听页面错误
        page.on('pageerror', (error) => {
            console.error(chalk.red(`页面错误: ${error.message}`));
        });

        // 监听console消息
        page.on('console', (msg) => {
            if (msg.type() === 'error') {
                console.error(chalk.red(`控制台错误: ${msg.text()}`));
            }
        });

        // 等待用户停止
        await new Promise((resolve) => {
            let isClosing = false;

            const cleanup = async () => {
                if (isClosing) return;
                isClosing = true;

                spinner.start('正在停止录制...');

                try {
                    await browser.close();
                    ffmpeg.kill('SIGINT');

                    // 等待FFmpeg完全结束
                    await new Promise((resolve) => {
                        ffmpeg.on('close', resolve);
                    });

                    spinner.succeed('录制已完成');
                    console.log(chalk.green(`\n视频已保存到: ${videoPath}`));
                } catch (error) {
                    spinner.fail('停止录制时出错');
                    console.error(chalk.red(error));
                }

                resolve();
            };

            // 监听中断信号
            process.on('SIGINT', cleanup);
            process.on('SIGTERM', cleanup);
        });

    } catch (error) {
        spinner.fail('录制过程出错');
        console.error(chalk.red(error));
        throw error;
    }
}

// 使用示例
recordBrowserAdvanced({
    url: 'https://www.taobao.com',
    width: 1280,
    height: 720,
    framerate: 30,
    quality: 18,
    outputDir: 'videos'
}).catch(() => process.exit(1));
