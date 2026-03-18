# docker环境配置

使用build.sh进行安装，脚本读取环境信息并依次构建base→R→cpu/gpu→final(cpu/gpu)。

** 使用方法 **
```bash
bash -x build.sh --mirror china --github-proxy http:// --final --gpu > build.log 2>&1 &
# 如果中途在某个stage出错中断，可以不从头开始构建
# bash -x build.sh --mirror china --github-proxy http:// --final --gpu --stage 3 > build.log 2>&1 & #从stage 3开始继续构建(stage3重建而后继续往下)
```
** 注意 **

因为RAPIDS目前最新的26.02仍然基于0.65以下的numba/ 1.x numpy构建，而scanpy新版则基于2.x numpy，存在冲突，因此GPU镜像锁定了部分软件版本

** 环境测试脚本 **

- Rbio_verify.R和Rbio_verify.py分别用于测试R包以及python包正确安装。
- AnalysisSample.py则用于模拟测试构建的RAPIDS运算容器能否正确加载cuda环境进行工作。
- AnalysisDemo.py用于载入nature文章（doi ：10.1038/s41586-024-07571-1）的[单细胞数据集](https://cellxgene.cziscience.com/collections/f11cb29c-b546-4738-9bd8-66ea621a7bd5 "Single-cell integration reveals metaplasia in inflammatory gut diseases")进行数据分析以测试GPU加速环境能否正常工作的脚本。 用法：将脚本和h5ad数据通过数据卷加载至容器内/data目录后，重命名数据为sample.h5ad，而后运行 `docker exec python /data/AnalysisDemo.py /data/sample.h5ad`
