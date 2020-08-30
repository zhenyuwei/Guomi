# 如何列出Linux下可执行文件依赖某个特定库(.so)的关系

最近需要统计Linux下软件(可执行文件)对某个特定库的依赖数,没有找到想要的工具,于是从网上找到一个[Python遍历文件](https://thispointer.com/python-how-to-get-list-of-files-in-directory-and-sub-directories/)的程序,对每个文件添加如下判断:

* 是否为可执行文件(shell [ -x file ])
* 是否是软链接(shell [ -L file ])
* 是否依赖特定库(仅考虑动态链接)(shell [ ldd file | grep -iE "filter" ])
