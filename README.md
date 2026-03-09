# Seurat+Signac(ArchR)+Azimuth+Giotto+Scanpy+Pytorch生信集合环境一键安装脚本

**该项目是一个基于Ubuntu 24.04的下列常用生信软件包集成环境的构建项目**

由于AI尤其是CLI工具的不断进步，生信分析门槛越来越低，利用CLI工具进行自动化分析的价值日益升高。但是CLI工具需要依赖于本地/远程有可访问的数据处理环境，因此需要先部署常用的生信分析环境。

思路一：分别创建独立的conda环境/docker环境/Renv/Python环境，然后把名称及调用方法写入CLI工具的知识库，让其自动调用。这样的优点是部署简单，尤其是docker构建，基本上直接拉官方镜像，然后分别设置不同的端口，结合Rstudio/Python的API或者通过docker run传入的方式调用运行即可。但这样的缺点是，若使用conda/renv/python venv，则同一个CLI需要频繁的激活/切换不同的环境，而且renv很难通过命令行进行激活；若使用docker，多个容器间沟通和目录挂载存在一定的限制，并且多容器的资源消耗较大。

思路二：部署一个包含可能共存的常用工具包的集成环境，然后让CLI进行调用。优点是非常适合CLI工具，缺点就是部署非常麻烦，需要解决各种依赖问题。

这里提供了一个包括以下经典软件的集成环境部署方法，由IFLOW工具结合我1个月的反复调试，提供了DOCKER和Conda两种部署方式，均在Ubuntu 24.04 + RTX5060ti环境下部署成功。

**Docker环境**: 部署文件位于docker文件夹内，参考其说明进行安装（构建R44的时候不了解，实际上基于rocker/geospatial系列镜像进行构建最省事）

**Conda环境**: 部署文件位于conda文件夹内，参考其说明进行安装

**建议提前下载BSgenome.Hsapiens.UCSC.hg38源码包至本地，否则容易出现网络错误**：可访问[Bioconductor](https://bioconductor.org/packages//release/data/annotation/html/BSgenome.Hsapiens.UCSC.hg38.html)获取当前版本的文件，然后先用下载软件高速下载。其中BSgenome.Hsapiens.UCSC.hg38_1.4.5.tar.gz是确认支持R4.4.3的。

## ArchR推荐使用官方docker镜像部署

R443文件夹内提供了包含Seurat+Signac+ArchR++Azimuth+Giotto+Scanpy+Pytorch的构建文件，由于ArchR在4.5版构建的依赖及其难以解决，这里提供R4.4.3环境下的构建文件，同样docker和conda各一份，但其他额外软件未经测试，需要的可以自行添加，国内只剩西湖大学镜像还有R 4.4匹配的bioconductor镜像。
该版本包安装一些新软件，BiocManager需要添加update = FALSE，以避免更新包导致需要解决一堆依赖问题。若非必须，更推荐ArchR单独构建一个docker容器（也可以基于参考conda脚本，注释掉stage5脚本内seurat、signac和azimuth的主包安装命令然后依次单独运行脚本）

## 包含的软件

Seurat是由Satija lab开发的常用的生信分析软件（https://github.com/satijalab），分别是常用的scRNAseq和scACAT-seq下游分析软件。

ArchR是由Greenleaf团队开发的生信分析软件（https://github.com/GreenleafLab/ArchR），可用于scACAT-seq分析

Signac是Stuart lab开发的scACAT-seq分析软件（https://github.com/stuart-lab/signac）

Giotto Suites是由Dries Lab开发的空间转录组分析套件（https://github.com/drieslab/Giotto）

Scanpy是python环境下常用的scRNAseq分析软件，最初由Theis Lab开发（https://github.com/scverse/scanpy）

Azimuth是由 Satija Lab 开发的基于Seurat v5和Shiny 的单细胞数据查询与参考映射工具（https://github.com/satijalab）。
