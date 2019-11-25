## 重签名工具

重签名工具支持 iPA 重签名，并且支持```appex```拓展应用重签名，依赖环境 MacOS。

依赖软件：**zip**，**unzip**

如果依赖软件不存在会导致重签名不成功，如果依赖软件不存在可以在控制台（**terminal.app**）使用以下命令安装：

```
brew install zip;
brew install unzip;
```

### 使用方法

#### 1.  打开软件，点击"**导入iPA**"，选择需要重签名的iPA应用包，导入后软件会自动解析iPA包获取信息。

<img src="./md-assets/1.png" style="width:40%;" />


#### 2. 点击应用描述文件下的"**更新**"按钮，更换新的应用描述文件，

![图片](https://uploader.shimo.im/f/fg4aaSgD6mURSx8D.png!thumbnail)



#### 3.  如果存在拓展应用，并且向重签拓展应用的描述文件，点击"**更新**"按钮，如果不想更新拓展应用的描述文件，软件将不会对拓展应用进行重签名。

![图片](https://uploader.shimo.im/f/Vy1TFiZT5xwemCHN.png!thumbnail)

#### 4.  确认"签名证书"，描述文件一定要找到匹配的发布证书进行重签名，否则重签名后的应用依旧失败。（**如果你很确认你本地的证书没有问题的话，你可以跳过这一步**）

**4.1  打印“新的描述文件”的Plist信息，并且获取 DeveloperCertificates 字段下的字符串**

在控制输入以下命令打印“描述文件”的信息：


```
security cms -D -i 新描述文件的路径
```

![图片](https://uploader.shimo.im/f/uE1XojZrfucmskQJ.png!thumbnail)


**4.2 新建一个 "test.cer" 文件，复制以下内容到文件中**

```
-----BEGIN CERTIFICATE-----
将 DeveloperCertificates 字段中的 <data></data> 之间的内容拷贝至此
-----END CERTIFICATE-----
```

**4.3 右键 "test.cer" 文件，点击快速查看**

![图片](https://uploader.shimo.im/f/EMWpfjliHHULfsut.png!thumbnail)   

**查看序列号**

  ![图片](https://uploader.shimo.im/f/WH4eQnmZUfgvxv45.png!thumbnail)


**4.4 打开"系统钥匙串"，查找重复的证书信息**

![图片](https://uploader.shimo.im/f/eqEbM7P3z8sMlXIS.png!thumbnail)

**4.5 依次点击点击“显示简介”，找到和描述文件一致的序列号的证书**

![图片](https://uploader.shimo.im/f/6hrKtp7GeFg5G4jY.png!thumbnail)

**4.6 查找到正确的证书后，向下滑动找到“SHA-1”指纹值**

![图片](https://uploader.shimo.im/f/7sePtp5Gi50DiLlN.png!thumbnail)

**4.7 在签名工具中找到对应指纹值的证书后，重签名就可以成功了。**

![图片](https://uploader.shimo.im/f/9uYq6ogGLJkzQoLg.png!thumbnail)



#### 5.  点击"**重签名**"按钮，稍等一会儿。

![图片](https://uploader.shimo.im/f/01Wnd2vod3InpjK6.png!thumbnail)

  

#### 6. 最后将重签名成功后的"iPA应用"保存到指定目录即可。


## 输出目录

点击输出目录可以查找到历史生成的"iPA"列表

![图片](https://uploader.shimo.im/f/DDrzOoWc8lcJ1Zj4.png!thumbnail)



### 重签名脚本

```epointfastsign.sh```, 为快速签名脚本，是整个儿原理的核心脚本，供同学们学习参考。


### FAQ

如果对软件有想法或者建议，可以在 ```issue``` 提出问题，并且欢迎 ```PR```。