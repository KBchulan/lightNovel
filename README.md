# lightNovel

&ensp;&ensp;基于flutter开发的轻小说的app，后端用的go语言，然后整个项目架构是REST API，差不多是这样，如果您有看小说的兴趣，完全可以自己跑一下或者直接使用我们的Release版本。

## 与一般小说app的区别

&ensp;&ensp;1. 无需登录注册，采用uuid作为标识，因此不需要担心任何权限问题，什么都没有要，很多个性化功能也是支持的，而且主要是小说(服务器代码也是开源的，完全可以查看)
&ensp;&ensp;2. 书签功能，我原来看小说到一些很喜欢的地方，但是没有书签功能，所以就自己写了一个，不仅可以随时定位到原有的位置，而且不干扰阅读历史，可以随时重温
&ensp;&ensp;3. 后续会开放一个enup上传接口，可以上传自己比较喜欢的小说，后端会解析到mongoDB里，这样就可以查看了

## 架构设计图

![架构设计图](./docs/frame.png)

## 效果截图

![效果截图](./docs/show.png)