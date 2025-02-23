这个实现的主要特点:
command.ps1:
使用try-catch块捕获所有可能的错误
当发生错误时，通过exit 1返回错误状态
可以包含多个Invoke-Sqlcmd命令
run.bat:
使用-NoProfile参数避免加载PowerShell配置文件，加快执行速度
使用-ExecutionPolicy Bypass确保脚本能够执行
通过检查%ERRORLEVEL%捕获PowerShell脚本的错误
当PowerShell脚本失败时返回1
当command.ps1执行出错时，错误信息会显示在控制台上，并且run.bat会捕获到这个错误并返回1作为退出码。
您可以根据实际需求修改command.ps1中的Invoke-Sqlcmd命令，添加具体的服务器名称、数据库名称、SQL脚本文件路径或存储过程名称。




在PowerShell中，Invoke-Sqlcmd确实有一些特殊的错误处理情况。让我们修改command.ps1来更好地处理这个问题：
主要改进：
添加了 $ErrorActionPreference = "Stop" 强制错误转换为异常
在Invoke-Sqlcmd中添加了 -ErrorAction Stop 参数
添加了 -QueryTimeout 0 防止超时
使用 $host.SetShouldExit(1) 确保错误状态被正确设置
添加了结果检查逻辑


这个改进版本应该能更好地捕获Invoke-Sqlcmd的错误。如果SQL执行过程中出现任何问题，脚本都会返回错误状态码1，并且错误信息会被正确显示。



$result -eq $null 是在检查变量 $result 是否为空值（null），但这种写法在PowerShell中其实不是最佳实践。让我为您解释并提供更好的写法：
在PowerShell中检查null值有以下几种推荐方式：
使用 $null 放在比较符号左边（推荐）：
$null -eq $result

使用 -not 操作符：
-not $result


为什么要把 $null 放在左边？
1. 这是PowerShell的最佳实践
可以避免一些潜在的问题，比如：
当 $result 是一个集合时，$result -eq $null 可能会对集合中的每个元素进行比较
把 $null 放在左边可以确保正确的比较行为
3. 性能略好一些
另外，在某些情况下，您可能需要检查更具体的条件，比如：
检查是否为空数组：$result.Count -eq 0
检查字符串是否为空：[string]::IsNullOrEmpty($result)
检查字符串是否为空或只包含空白：[string]::IsNullOrWhiteSpace($result)




工作流程：
当PowerShell脚本执行exit 1时：
PowerShell进程结束
这个退出码(1)会传递给调用它的批处理脚本
在批处理脚本中，这个值会存储在%ERRORLEVEL%变量中
2. 错误码传递链：
PowerShell脚本的exit 1 →
批处理脚本的%ERRORLEVEL%变量 →
批处理脚本的exit /b 1 →
调用批处理脚本的程序
常见的退出码：
0：表示成功执行
1（或其他非0值）：表示执行出错
所以在这个例子中：
如果SQL执行出错，PowerShell脚本返回1
批处理脚本检测到%ERRORLEVEL% NEQ 0条件成立
批处理脚本也返回1表示错误
这就是为什么我们在PowerShell脚本中同时使用：


实际上，在这种情况下，我们只需要使用其中一个就够了。让我解释一下这两行代码的区别：
$host.SetShouldExit(1)
这是设置PowerShell宿主的退出码
在某些特殊的PowerShell宿主环境中可能需要
不是所有场景都必需
exit 1
这是最直接和通用的方式
立即终止脚本执行并返回错误码
这个错误码会直接传递给%ERRORLEVEL%
在我们的场景中，只使用exit 1就足够了。让我修改代码：



在批处理脚本(bat文件)中，exit /b 和 exit 有重要的区别：
exit /b：
只退出当前批处理脚本
不会关闭命令提示符窗口
返回到调用此批处理的程序
常用于函数或子程序的返回
exit（不带/b）：
完全退出cmd.exe进程
会关闭命令提示符窗口
终止所有批处理处理