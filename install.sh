conda deactivate
conda env remove -y -n bio
conda clean -a -y
mamba clean -a -y
conda create -n bio -y r-base=4.4.3 python=3.12 mamba
conda create -n bio5 -y --clone bio4
conda activate bio
cp /home/hrply/software/sh/R-bio/.test/logs/output.log /home/hrply/software/sh/R-bio/.test/logs/output.log.bak_$(date +%Y%m%d_%H%M%S) 2>/dev/null; > /home/hrply/software/sh/R-bio/.test/logs/output.log
pkill -9 -f "Rbio_" 2>/dev/null> /home/hrply/software/sh/R-bio/.test/logs/output.log
bash /home/hrply/software/sh/R-bio/Rbio_stage_gpu.sh --china > /home/hrply/software/sh/R-bio/.test/logs/output.log 2>&1 &
## [1] stats     graphics  grDevices utils     datasets  methods   base     
## 
## other attached packages:
## [1] circlize_0.4.15
## 
## loaded via a namespace (and not attached):
##  [1] bookdown_0.24       digest_0.6.29       R6_2.5.1           
##  [4] grid_4.1.2          jsonlite_1.7.2      magrittr_2.0.1     
##  [7] evaluate_0.14       stringi_1.7.6       rlang_0.4.12       
## [10] GlobalOptions_0.1.2 jquerylib_0.1.4     bslib_0.3.1        
## [13] rmarkdown_2.11      tools_4.1.2         stringr_1.4.0      
## [16] xfun_0.29           yaml_2.2.1          fastmap_1.1.0      
## [19] compiler_4.1.2      colorspace_2.0-2    shape_1.4.6        
## [22] htmltools_0.5.2     knitr_1.37          sass_0.4.0