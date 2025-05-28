const { spawn } = require('child_process');
const path = require('path');

/**
 * 将字幕文件合并到视频中
 * @param {string} videoPath - 视频文件路径
 * @param {string} subtitlePath - 字幕文件路径
 * @param {string} outputPath - 输出文件路径
 * @param {string} subtitleFormat - 字幕格式 ('srt' 或 'ass')
 * @returns {Promise} - 返回处理结果的 Promise
 */
function mergeSubtitleWithVideo(videoPath, subtitlePath, outputPath, subtitleFormat = 'srt') {
    return new Promise((resolve, reject) => {
        // 构建 ffmpeg 命令
        const ffmpegArgs = [
            '-i', videoPath,
            '-i', subtitlePath,
            '-c:v', 'copy',
            '-c:a', 'copy',
            '-c:s', 'mov_text',
            '-map', '0:v',
            '-map', '0:a',
            '-map', '1:0',
            outputPath
        ];

        // 执行 ffmpeg 命令
        const ffmpeg = spawn('ffmpeg', ffmpegArgs);

        ffmpeg.stdout.on('data', (data) => {
            console.log(`输出: ${data}`);
        });

        ffmpeg.stderr.on('data', (data) => {
            console.log(`处理中: ${data}`);
        });

        ffmpeg.on('close', (code) => {
            if (code === 0) {
                resolve('字幕合并完成！');
            } else {
                reject(new Error(`处理失败，错误代码: ${code}`));
            }
        });
    });
}

// 使用示例
async function main() {
    // 获取命令行参数
    const [inputVideo, subtitleFile, outputVideo] = process.argv.slice(2);

    if (!inputVideo || !subtitleFile || !outputVideo) {
        console.log('使用方法: node record-with-subtitle.js <输入视频> <字幕文件> <输出视频>');
        return;
    }

    try {
        await mergeSubtitleWithVideo(
            inputVideo,    // 输入视频文件
            subtitleFile,  // 字幕文件
            outputVideo,   // 输出视频文件
            'srt'         // 字幕格式
        );
        console.log('视频处理完成！');
    } catch (error) {
        console.error('处理出错:', error);
    }
}

main();

// node record-with-subtitle.js input.mp4 subtitle.srt output_with_sub.mp4


/* 
1
00:00:01,000 --> 00:00:04,000
这是第一行字幕

2
00:00:04,500 --> 00:00:08,000
这是第二行字幕 

*/