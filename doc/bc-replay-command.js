async function userPasswordAuthenticate(page, url, username, password) {
    try {
        console.log('开始登录流程...');
        
        // 等待页面加载完成
        await page.waitForLoadState('networkidle', { timeout: 30000 });
        console.log('页面加载完成');
        
        // 调试信息：输出当前URL
        console.log('当前页面URL:', page.url());
        
        // 等待并确保用户名输入框可见和可交互
        console.log('等待用户名输入框...');
        await page.waitForSelector('input[name=UserName]', { 
            state: 'visible',
            timeout: 30000 
        });
        console.log('找到用户名输入框');
        
        // 输出页面上所有输入框的信息
        const inputs = await page.$$eval('input', inputs => 
            inputs.map(input => ({
                type: input.type,
                name: input.name,
                id: input.id,
                visible: input.offsetParent !== null
            }))
        );
        console.log('页面上的输入框:', inputs);

        // 清除输入框并填写用户名
        await page.waitForSelector('input[name=UserName]', { 
            state: 'visible',
            timeout: 30000 
        });
        
        await page.fill('input[name=UserName]', username);

        // 等待密码输入框
        await page.waitForSelector('input[name=Password]', { 
            state: 'visible',
            timeout: 30000 
        });
        
        await page.fill('input[name=Password]', password);

        // 等待提交按钮并点击
        await page.waitForSelector('button[type=submit]', {
            state: 'visible',
            timeout: 30000
        });
        
        // 使用 Promise.all 确保等待导航完成
        await Promise.all([
            page.waitForNavigation({ 
                timeout: 60000,
                waitUntil: 'networkidle' 
            }),
            page.click('button[type=submit]')
        ]);

        // 等待页面完全加载
        await page.waitForLoadState('networkidle', { timeout: 30000 });
        
    } catch (error) {
        console.error('登录过程出错:', error);
        
        // 获取更多调试信息
        try {
            const screenshot = await page.screenshot({ 
                path: 'login-error.png',
                fullPage: true 
            });
            console.log('错误截图已保存为 login-error.png');
            
            // 输出更详细的页面信息
            const content = await page.content();
            console.log('页面HTML内容:', content);
            
            // 输出所有可见元素
            const visibleElements = await page.$$eval('*', elements =>
                elements.filter(el => el.offsetParent !== null)
                    .map(el => ({
                        tag: el.tagName,
                        id: el.id,
                        class: el.className,
                        text: el.innerText
                    }))
            );
            console.log('可见元素:', visibleElements);
            
        } catch (e) {
            console.error('无法获取调试信息:', e);
        }
        
        throw error;
    }
}




























try {
        console.log('开始登录流程...');
        
        // 处理 HTTP Basic Authentication
        // 方法1：在 URL 中直接包含认证信息
        const urlObj = new URL(url);
        const authenticatedUrl = `${urlObj.protocol}//${username}:${password}@${urlObj.host}${urlObj.pathname}${urlObj.search}`;
        await page.goto(authenticatedUrl);

        // 方法2：使用 authenticate 方法
        await page.authenticate({
            username: username,
            password: password
        });

        // 等待页面加载完成
        await page.waitForLoadState('networkidle', { timeout: 30000 });
        console.log('页面加载完成');

        // 验证是否登录成功
        const currentUrl = page.url();
        console.log('当前页面URL:', currentUrl);
        
        if (currentUrl.includes('login') || currentUrl.includes('auth')) {
            throw new Error('登录可能未成功，当前URL包含登录相关路径');
        }

    } catch (error) {
        console.error('登录过程出错:', error);
        
        // 获取更多调试信息
        try {
            const screenshot = await page.screenshot({ 
                path: 'login-error.png',
                fullPage: true 
            });
            console.log('错误截图已保存为 login-error.png');
            
            // 由于是 HTTP 认证，无法获取 HTML 内容
            console.log('当前URL:', page.url());
            
        } catch (e) {
            console.error('无法获取调试信息:', e);
        }
        
        throw error;
    }
}

// 在 userPasswordAuthenticate 函数开始时添加
page.on('dialog', async dialog => {
    console.log('检测到对话框:', {
        type: dialog.type(),
        message: dialog.message()
    });
    await dialog.accept(); // 或 dialog.dismiss() 取决于需要
});

page.on('request', request => {
    console.log('请求:', {
        url: request.url(),
        headers: request.headers(),
        method: request.method()
    });
});

page.on('response', response => {
    console.log('响应:', {
        url: response.url(),
        status: response.status(),
        headers: response.headers()
    });
});

















