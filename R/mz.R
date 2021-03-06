
#' preProcess + predict itself
#' @description reProcess + predict itself
#' @param x  x
#' @note short for the following example:
#' \cr prep <- preProcess(x, method = c("BoxCox","center", "scale"))
#' \cr x <- predict(prep, x)
#' @export
mz.precess = function(x,...){
    preProcessObj=caret::preProcess(x,...)
    return(predict(preProcessObj,x))
}

#' summaryFunction = fiveStats
#' @description summaryFunction = fiveStats
#' @export
fiveStats <- function(...) c(twoClassSummary(...), defaultSummary(..))

#' getModelInfo
#' @description \code{\link[caret]{getModelInfo}}
#' @param model train method name
#' @param regex T/F, matching with regex or not
#' @return returns an invisible data frame
#' @seealso \url{http://topepo.github.io/caret/available-models.html}
#' @export
mz.models = function(model = NULL, regex = TRUE, ...){
    models = ez.header('model_label'=character(),'method'=character(),'type'=character(),'library'=character(),'tuning_parameters'=character())
    modelLists = caret::getModelInfo(model=model,regex=regex,...)
    for (theMethod in names(modelLists)) {
        modelList = modelLists[[theMethod]]
        theLabel = toString(modelList$label)
        theType = toString(modelList$type)
        theLibrary = toString(modelList$library)
        theParameter = toString(paste0(modelList$parameters$parameter,' (',modelList$parameters$label,') '))
        models = ez.append(models,list(theLabel,theMethod,theType,theLibrary,theParameter),print2screen=F)
    }
    View(models)
    cat(sprintf('caret::getModelInfo("%s")[[i]] to see more details\n',model))
    return(invisible(models))
}

#' generate modified friedman1 data set: 5 real, 5 uniform noise, 5 correlated with real (rs>.97), p-15 normal noise
#' @description generate modified friedman1 data set: 5 real, 5 uniform noise, 5 correlated with real, p-15 normal noise
#' @param n sample size
#' @param p total predictors (>15)
#' @return y is numeric vector, x is numeric data frame, already z scored (to matrix: data.matrix(x)), xy is a data frame with xy
#' @note Y = 10sin(pi X1 X2) + 20(X3 − 0.5)^2 + 10 X4 + 5 X5 + e
#' @export
mz.friedman1 = function(n=100,p=55) {
    set.seed(1)
    p <- p - 15
    sigma <- 1
    sim <- mlbench::mlbench.friedman1(n, sd = sigma)
    colnames(sim$x) <- c(paste("real", 1:5, sep = ""),
                         paste("uni", 1:5, sep = ""))
    correlate <- base::jitter(sim$x[,1:5],factor=5000)
    colnames(correlate) <- paste("cor", 1:5, sep = "")
    normal <- matrix(rnorm(n * p), nrow = n)
    colnames(normal) <- paste("norm", 1:ncol(normal), sep = "")
    x <- cbind(sim$x, correlate, normal)
    x = mz.precess(x,method = c("center", "scale"))
    y <- sim$y
    x = data.frame(x)
    xy = x; xy$y = y
    result = list(y=y,x=x,xy=xy)
    # or list2env(.R_GlobalEnv)
    list2env(result, globalenv())
    return(invisible(NULL))
}

#' sbf selected features: among resamples, univariate vars selected, how many times (or percentage) appeared in the resamples. col sorted by appearance percentage
#' @description sbf selected features: among resamples, univariate vars selected, how many times (or percentage) appeared in the resamples. col sorted by appearance percentage
#' @export
mz.sbfself = function(sbfObj){
    tmp = sort(table(unlist(sbfObj$variables)), decreasing = TRUE)
    result = data.frame('var'=names(tmp),'appearance'=as.numeric(unname(tmp)/length(sbfObj$variables)))
    return(result)
}

#' only for RF: pass modrf, plot raw Importance >0, return a sorted df
#' @description only for RF: pass modrf, plot Importance >0, return an invisible sorted df
#' @export
varImpRF = function(modrf,plot=T,scale=F) {
    varimprf = varImp(modrf,scale=scale)
    result = varimprf$importance %>% 
             tibble::rownames_to_column(var='variable') %>% 
             arrange(desc(Overall))

    varimprf$importance = varimprf$importance[which(varimprf$importance>0),,drop=F]
    if (plot) varimprf %>% plot() %>% print()

    return(invisible(result))
}

#' only for RFE: pass rfeObj, plot optVar averaged importance across OptSized resamples, return an invisible df
#' @description only for RFE: pass rfeObj, plot optVar averaged importance across OptSized resamples, return an invisible df
#' @export
varImpRFE = function(rfeObj,plot=T) {
    # see code https://github.com/topepo/caret/blob/master/pkg/caret/R/rfe.R#L1306
    varimprfe = varImp(rfeObj,drop=T) 
    # drop other variables that are not final optVar, when restricting to OptSize
    result = varimprfe %>% 
             tibble::rownames_to_column(var='variable') 
    
    # same code from https://github.com/topepo/caret/blob/master/pkg/caret/R/plot.varImp.train.R
    tmp = result; names(tmp) = c('Feature','Importance')
    featureNames <- tmp$Feature
    tmp$Feature <- factor(rep(featureNames, 1),
                          levels = rev(featureNames)) 
    if (plot) print( lattice::dotplot(Feature~Importance,tmp,
                    xlab = list(cex=2.5, fontfamily='Times New Roman'),
                    ylab = list(cex=2.5, fontfamily='Times New Roman'),
                    panel = panel.needle,
                    panel = function(...) {
                          panel.dotplot(..., col.line = "transparent")
                    }) )

    return(invisible(result))
}