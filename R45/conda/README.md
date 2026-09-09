# conda环境配置

使用Rbio_install.sh进行安装，脚本读取环境信息并依次运行Rbio_1.sh~Rbio_4.sh，然后是Rbio_python.sh。脚本里的Rbio_extra.sh是作为一个temple为后续增加自定义包使用的，它会加载Rbio_common.sh从而加载必要的变量信息。你可以把github_token写入.github_token，用于安装过程中进行github文件拉取

** 使用方法 **
```bash
conda activate your_conda_env_name
cd conda
bash -x Rbio_install.sh --china > Rbio.log 2>&1 & #使用中国镜像源
# 如果中途在某个stage出错中断，可以不从头开始构建
#./Rbio_install.sh --stage 3 --china > Rbio.log 2>&1 & #从stage 3开始继续构建
#./Rbio_install.sh --proxy http://192.168.3.147:7890 --china > Rbio.log 2>&1 & #代理设置
cd RAPIDS
bash -x build_cu130.sh #如果是早期显卡，就用cu128版
```
** 注意 **

基于官方说明，RAPIDS最好通过conda安装，包括依赖的pytorch以及其他CUDA依赖，避免和系统依赖冲突，也较pypi更稳定。而所有生信软件推荐通过pip安装，更新快，且能够避免conda/mamba解析大量已有预编译包的依赖关系时卡住。

由于docker容器在稳定和可移植的优越性，而python包很多时候更新很快，因此为避免conda环境被pip更新所干扰，还额外提供了一个python生信环境的docker容器配置脚本(./RAPIDS)。

** 环境测试脚本 **

- Rbio_verify.R和Rbio_verify.py分别用于测试conda环境内R包是否正确安装，以及python包在conda和docker容器内是否正确安装。
- AnalysisSample.py则用于模拟测试构建的RAPIDS运算容器能否正确加载cuda环境进行工作。
- AnalysisDemo.py用于载入nature文章（doi ：10.1038/s41586-024-07571-1）的[单细胞数据集](https://cellxgene.cziscience.com/collections/f11cb29c-b546-4738-9bd8-66ea621a7bd5 "Single-cell integration reveals metaplasia in inflammatory gut diseases")进行数据分析以测试GPU加速环境能否正常工作的脚本。 用法：将脚本和h5ad数据通过数据卷加载至容器内/data目录后，重命名数据为sample.h5ad，而后运行 `docker exec python /data/AnalysisDemo.py /data/sample.h5ad`
