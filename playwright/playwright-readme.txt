D:\hsbc-space\play-test>npm install @playwright/test

added 3 packages in 2s

D:\hsbc-space\play-test>npx playwright install chromium
Downloading Chromium 133.0.6943.16 (playwright build v1155) from https://cdn.playwright.dev/dbazure/download/playwright/builds/chromium/1155/chromium-win64.zip140 MiB [======140140140 Mi140140 MiB [======   140 Mi140140 MiB [====================] 100% 0.0s
Chromium 133.0.6943.16 (playwright build v1155) downloaded to C:\Users\Administrator\AppData\Local\ms-playwright\chromium-1155
Downloading FFMPEG playwright build v1011 from https://cdn.playwright.dev/dbazure/download/playwright/builds/ffmpeg/1011/ffmpeg-win64.zip       
1.3 MiB [====================] 100% 0.0s
FFMPEG playwright build v1011 downloaded to C:\Users\Administrator\AppData\Local\ms-playwright\ffmpeg-1011
Downloading Chromium Headless Shell 133.0.6943.16 (playwright build v1155) from https://cdn.playwright.dev/dbazure/download/playwright/builds/chromium/1155/chromium-headless-shell-win64.zip
87.4 MiB [====================] 100% 0.0s
Chromium Headless Shell 133.0.6943.16 (playwright build v1155) downloaded to C:\Users\Administrator\AppData\Local\ms-playwright\chromium_headless_shell-1155
Downloading Winldd playwright build v1007 from https://cdn.playwright.dev/dbazure/download/playwright/builds/winldd/1007/winldd-win64.zip       
0.1 MiB [====================] 100% 0.0s
Winldd playwright build v1007 downloaded to C:\Users\Administrator\AppData\Local\ms-playwright\winldd-1007


# 最简单的方式
npx playwright codegen

# 指定起始URL
npx playwright codegen https://your-website.com

# 指定浏览器
npx playwright codegen --browser chromium
npx playwright codegen --browser firefox
npx playwright codegen --browser webkit


# 生成特定语言的代码
npx playwright codegen --target javascript  # JavaScript
npx playwright codegen --target python     # Python
npx playwright codegen --target java       # Java
npx playwright codegen --target csharp     # C#

# 指定视口大小
npx playwright codegen --viewport-size=800,600

# 模拟移动设备
npx playwright codegen --device="iPhone 12"


# 打开录制窗口后：
# 1. 点击 "Record" 开始录制
# 2. 在目标网站上进行操作
# 3. 使用工具栏功能：
#   - 暂停/继续录制
#   - 复制生成的代码
#   - 清除录制内容
#   - 保存到文件



# 1. 设置环境
mkdir test-recording
cd test-recording
npm init -y
npm install @playwright/test

# 2. 创建配置文件 playwright.config.js
npx playwright install

# 3. 开始录制，指定输出文件
npx playwright codegen --output my-test.spec.js

# 4. 使用录制器的高级功能：
# - 检查元素选择器
# - 修改等待条件
# - 添加断言



# 1. 安装 Playwright VS Code 插件
# 2. 使用命令面板 (Ctrl+Shift+P)
# 3. 输入 "Playwright: Record new test"
# 4. 选择测试文件位置
# 5. 开始录制


// 在生成的代码中添加调试点
await page.pause();  // 添加断点

// 使用 --debug 标志运行
npx playwright test --debug

// 放慢录制的操作
npx playwright codegen --slow-mo=1000


// 在录制时，可以使用工具栏的选择器编辑器来：
// 1. 优化选择器
// 2. 添加等待条件
// 3. 处理动态加载的内容



# 1. 在项目中安装依赖
npm install --save-dev @playwright/test

# 2. 创建测试目录
mkdir tests

# 3. 开始录制到特定文件
npx playwright codegen --output tests/my-test.spec.js

# 4. 运行测试
npx playwright test




# 安装 playwright
npm init playwright@latest

# 或者直接安装
npm install @playwright/test




# 只安装 Chromium 浏览器
npx playwright install chromium








// playwright.config.js
const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  // 只使用 chromium
  projects: [
    {
      name: 'chromium',
      use: {
        browserName: 'chromium',
        // 其他配置
        viewport: { width: 1280, height: 720 },
        // 如果需要有头模式（显示浏览器）
        headless: false,
      },
    },
  ],
  // 其他全局配置
  timeout: 30000,
});








# 设置只下载 chromium
set PLAYWRIGHT_BROWSERS_TO_INSTALL=chromium
# 或在 Linux/Mac 上
export PLAYWRIGHT_BROWSERS_TO_INSTALL=chromium

# 然后安装
npx playwright install


{
  "scripts": {
    "test": "playwright test",
    "test:headed": "playwright test --headed",
    "test:ui": "playwright test --ui"
  }
}



# 创建项目目录
mkdir my-playwright-tests
cd my-playwright-tests

# 初始化 npm 项目
npm init -y



# 安装 Playwright 和 Chromium
npm install @playwright/test
npx playwright install chromium


mkdir tests
mkdir test-results
mkdir playwright-report



// playwright.config.js
const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './tests',  // 测试文件目录
  outputDir: './test-results', // 测试结果目录
  
  // 只使用 Chromium
  projects: [
    {
      name: 'chromium',
      use: {
        browserName: 'chromium',
        headless: false,  // 有头模式，方便调试
        viewport: { width: 1280, height: 720 },
        video: 'on',  // 录制视频
        screenshot: 'on',  // 失败时截图
      },
    },
  ],

  // 报告配置
  reporter: [
    ['html', { outputFolder: 'playwright-report' }],
    ['list']  // 控制台输出
  ],
  
  // 超时设置
  timeout: 30000,
  expect: {
    timeout: 5000
  },
});





// tests/example.spec.js
const { test, expect } = require('@playwright/test');

test('基本测试示例', async ({ page }) => {
  // 访问页面
  await page.goto('https://your-website.com');
  
  // 等待元素
  await page.waitForSelector('.login-form');
  
  // 填写表单
  await page.fill('#username', 'testuser');
  await page.fill('#password', 'testpass');
  
  // 点击按钮
  await page.click('#login-button');
  
  // 验证结果
  await expect(page.locator('.welcome-message')).toBeVisible();
});




{
  "name": "my-playwright-tests",
  "version": "1.0.0",
  "scripts": {
    "test": "playwright test",
    "test:headed": "playwright test --headed",
    "test:ui": "playwright test --ui",
    "test:debug": "playwright test --debug",
    "show-report": "playwright show-report playwright-report",
    "codegen": "playwright codegen"
  }
}



// tests/utils/helpers.js
async function login(page, username, password) {
  await page.fill('#username', username);
  await page.fill('#password', password);
  await page.click('#login-button');
}

async function waitForPageLoad(page) {
  await page.waitForLoadState('networkidle');
}

module.exports = {
  login,
  waitForPageLoad
};




// tests/data/test-data.js
module.exports = {
  users: {
    admin: {
      username: 'admin',
      password: 'admin123'
    },
    user: {
      username: 'user',
      password: 'user123'
    }
  },
  urls: {
    baseUrl: 'https://your-website.com',
    loginPage: '/login',
    dashboard: '/dashboard'
  }
};



node_modules/
test-results/
playwright-report/
/playwright/.cache/



# 运行所有测试
npm test

# 使用 UI 模式运行
npm run test:ui

# 使用调试模式运行
npm run test:debug

# 生成测试代码
npm run codegen



my-playwright-tests/
├── node_modules/
├── tests/
│   ├── example.spec.js
│   ├── utils/
│   │   └── helpers.js
│   └── data/
│       └── test-data.js
├── test-results/
├── playwright-report/
├── playwright.config.js
├── package.json
└── .gitignore



主要特点：
清晰的项目结构
可重用的工具函数
集中管理的测试数据
完整的配置文件
多种运行模式支持
测试报告生成
视频录制和截图功能
调试工具支持
这样就建立了一个完整的 Playwright 测试项目框架，可以开始编写和运行测试了。