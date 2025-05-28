#!/usr/bin/env node

import { spawn } from 'child_process';
import ora from 'ora';
import chalk from 'chalk';
import path from 'path';
import fs from 'fs/promises';

// 解析命令行参数
function parseArgs() {
    const args = process.argv.slice(2); // 去掉前两个参数（node和脚本路径）
    const params = {};

    for (let i = 0; i < args.length; i += 2) {
        const flag = args[i];
        const value = args[i + 1];

        switch (flag) {
            case '-i':
                params.inputPath = value;
                break;
            case '-o':
                params.outputPath = value;
                break;
            case '-s':
                params.startTime = value;
                break;
            case '-e':
                params.endTime = value;
                break;
        }
    }

    // 验证必要参数
    if (!params.inputPath || !params.outputPath || !params.startTime || !params.endTime) {
        console.log('使用方法: node video-cut.js -i 输入文件 -o 输出文件 -s 开始时间 -e 结束时间');
        console.log('示例: node video-cut.js -i input.mp4 -o output.mp4 -s 00:01:30 -e 00:02:00');
        process.exit(1);
    }

    return params;
}

// 添加进度显示函数
function handleFFmpegProgress(data, spinner) {
    const message = data.toString();
    if (message.includes('time=')) {
        const timeMatch = message.match(/time=(\d{2}:\d{2}:\d{2}.\d{2})/);
        if (timeMatch) {
            spinner.text = `处理中: ${timeMatch[1]}`;
        }
    }
}

async function cutVideo(options = {}) {
    const {
        inputPath,          // 输入视频路径
        outputPath,         // 输出视频路径
        startTime,          // 要删除片段的开始时间（格式：HH:mm:ss）
        endTime,           // 要删除片段的结束时间（格式：HH:mm:ss）
    } = options;

    const spinner = ora('准备处理视频...').start();

    try {
        const outputDir = path.dirname(outputPath);
        await fs.mkdir(outputDir, { recursive: true });

        // 如果开始时间是 0，直接从 endTime 开始截取到结束
        if (startTime === '00:00:00') {
            await new Promise((resolve, reject) => {
                const ffmpeg = spawn('ffmpeg', [
                    '-i', inputPath,
                    '-ss', endTime,
                    '-c', 'copy',
                    outputPath
                ]);

                ffmpeg.stderr.on('data', (data) => handleFFmpegProgress(data, spinner));

                ffmpeg.on('close', (code) => {
                    if (code === 0) resolve();
                    else reject(new Error('视频处理失败'));
                });
            });

            spinner.succeed('视频处理完成！');
            console.log(chalk.green(`\n输出文件保存在: ${outputPath}`));
            return;
        }
        // 如果结束时间是 end，表示删除从 startTime 到结尾
        else if (endTime.toLowerCase() === 'end') {
            await new Promise((resolve, reject) => {
                const ffmpeg = spawn('ffmpeg', [
                    '-i', inputPath,
                    '-t', startTime,  // 只保留开始时间之前的部分
                    '-c', 'copy',
                    outputPath
                ]);

                ffmpeg.stderr.on('data', (data) => handleFFmpegProgress(data, spinner));

                ffmpeg.on('close', (code) => {
                    if (code === 0) resolve();
                    else reject(new Error('视频处理失败'));
                });
            });

            spinner.succeed('视频处理完成！');
            console.log(chalk.green(`\n输出文件保存在: ${outputPath}`));
            return;
        }

        // 生成临时文件路径
        const tempFile1 = path.join(outputDir, 'temp1.mp4');
        const tempFile2 = path.join(outputDir, 'temp2.mp4');

        // 第一步：提取删除段之前的部分
        await new Promise((resolve, reject) => {
            const ffmpeg1 = spawn('ffmpeg', [
                '-i', inputPath,
                '-t', startTime,
                '-c', 'copy',
                tempFile1
            ]);

            ffmpeg1.on('close', (code) => {
                if (code === 0) resolve();
                else reject(new Error('第一段视频提取失败'));
            });
        });

        spinner.text = '第一段视频提取完成...';

        // 第二步：提取删除段之后的部分
        await new Promise((resolve, reject) => {
            const ffmpeg2 = spawn('ffmpeg', [
                '-i', inputPath,
                '-ss', endTime,
                '-c', 'copy',
                tempFile2
            ]);

            ffmpeg2.on('close', (code) => {
                if (code === 0) resolve();
                else reject(new Error('第二段视频提取失败'));
            });
        });

        spinner.text = '第二段视频提取完成...';

        // 第三步：合并两段视频
        await new Promise((resolve, reject) => {
            // 创建一个包含要合并文件列表的临时文件
            const listPath = path.join(outputDir, 'filelist.txt');
            const fileContent = `file '${tempFile1}'\nfile '${tempFile2}'`;

            fs.writeFile(listPath, fileContent, 'utf8').then(() => {
                const ffmpeg3 = spawn('ffmpeg', [
                    '-f', 'concat',
                    '-safe', '0',
                    '-i', listPath,
                    '-c', 'copy',
                    outputPath
                ]);

                ffmpeg3.on('close', async (code) => {
                    // 清理临时文件
                    await Promise.all([
                        fs.unlink(tempFile1),
                        fs.unlink(tempFile2),
                        fs.unlink(listPath)
                    ]).catch(console.error);

                    if (code === 0) resolve();
                    else reject(new Error('视频合并失败'));
                });
            });
        });

        spinner.succeed('视频处理完成！');
        console.log(chalk.green(`\n输出文件保存在: ${outputPath}`));

    } catch (error) {
        spinner.fail('视频处理失败');
        console.error(chalk.red(error));
        throw error;
    }
}

// 获取参数并执行
const params = parseArgs();
cutVideo({
    inputPath: params.inputPath,
    outputPath: params.outputPath,
    startTime: params.startTime,
    endTime: params.endTime
}).catch(() => process.exit(1));


// node video-cut.js -i input.mp4 -o output.mp4 -s 00:01:30 -e 00:02:00


// # 删除开头 1分30秒
// node video-cut.js -i input.mp4 -o output.mp4 -s 00:00:00 -e 00:01:30

// # 删除中间 1分30秒到2分钟
// node video-cut.js -i input.mp4 -o output.mp4 -s 00:01:30 -e 00:02:00

// # 删除 1分30秒到结尾
// node video-cut.js -i input.mp4 -o output.mp4 -s 00:01:30 -e end