import { spawn } from 'child_process';
import { chromium } from '@playwright/test';
// import robot from 'robotjs'; // 需要安装：npm install robotjs

async function recordBrowserWindow() {
    // 启动浏览器
    const browser = await chromium.launch({
        headless: false,
        args: [
            '--window-size=1280,720',
            '--window-position=0,0'
        ]
    });

    const page = await browser.newPage();
    await page.setViewportSize({ width: 1280, height: 720 });

    // 等待一下以确保窗口位置已设置
    await new Promise(resolve => setTimeout(resolve, 1000));

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const videoPath = `videos/browser-${timestamp}.mp4`;

    // 启动FFmpeg录制特定区域
    const ffmpeg = spawn('ffmpeg', [
        '-f', 'gdigrab',
        '-framerate', '30',
        '-offset_x', '0',         // 录制区域的X坐标
        '-offset_y', '0',         // 录制区域的Y坐标
        '-video_size', '1280x720', // 录制区域大小
        '-i', 'desktop',
        '-c:v', 'libx264',
        '-preset', 'ultrafast',
        '-crf', '18',
        videoPath
    ]);

    // 导航到目标网站
    await page.goto('https://example.com');

    console.log('录制已开始，按 Ctrl+C 停止...');

    // 等待用户手动停止
    await new Promise((resolve) => {
        process.on('SIGINT', async () => {
            console.log('正在停止录制...');
            await browser.close();
            ffmpeg.kill('SIGINT');
            resolve();
        });
    });

    console.log(`视频已保存到: ${videoPath}`);
}

recordBrowserWindow().catch(console.error);