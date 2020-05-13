library(raster)
library(rgdal)
library(randomForest)
library(caret)
library(reprtree)
#library(doParallel)
# set working directory
setwd("~/Documents/RS/rcode")

###################prepare data##################
#load Landsat composite
L815 <- brick("sat15_com.tif")

#load training data
trainData <- shapefile("train2015_test/trainRF2015.shp")
plot(trainData)

#after loading L815 and trainData 
e <- extent(L815)
r <- rasterize(trainData,raster(res=30,xmn = e[1], xmx = e[2], ymn = e[3], ymx = e[4]), field="value")
r_nonna <- !is.na(r[])
s <- stack(L815,r)
val <- s[r_nonna]
val_df <- na.omit(data.frame(val))
names(val_df) <- c('b1','b2','b3','b4','b5','b6','b7','lc')
val_df$lc <- as.factor(val_df$lc)

#####################tune parameters##################
rf_tune50 <- tuneRF(x=val_df[,1:7], y=val_df[,8], ntreeTry=50, stepFactor=500)
rf_tune100 <- tuneRF(x=val_df[,1:7], y=val_df[,8], ntreeTry=100, stepFactor=500)
rf_tune300 <- tuneRF(x=val_df[,1:7], y=val_df[,8], ntreeTry=300, stepFactor=500)
rf_tune500 <- tuneRF(x=val_df[,1:7], y=val_df[,8], ntreeTry=500, stepFactor=500)

total_tune <- rbind(rf_tune50, rf_tune100, rf_tune300 rf_tune500)
m <- matrix(total_tune[,2], nrow = 3, ncol = 4, dimnames = list(c("1","2","7"), c("50","100","300","500")) )

matplot(rownames(m), m, type='l', xlab='mtry', ylab='OOB Error', lty=1, col=2:5)
legend( 'topright', inset=.05, legend=colnames(m), title = 'ntree',
       pch=1, horiz=TRUE, col=2:5)

################## #test multicollinearity ###########
mc <- multi.collinear(val_df[,1:7])
mc
################### train model ###################
rf <- randomForest(lc ~ .,
                   data=val_df,
                   ntree=500,
                   mtry=2,
                   importance=TRUE,
                   na.action=na.roughfix)
                   
############## evaluate the model ############
print(rf)mo
attributes(rf)
plot(rf)

#variable importance
varImpPlot(rf)
importance(rf)
# Look at the firsr trees in the forest.
tree <- getTree(rf, k=1, labelVar=TRUE)
reprtree:::plot.getTree(rf)

################ prediction ############
# prepare new image dataset:
class_img <- L815
names(class_img) <- c('b1','b2','b3','b4','b5','b6','b7')

# predict the whole image
rf_15 <- predict(class_img, model=rf, na.rm=T)

######## show results ##########
colors_ <- palette(colors()[1:2])
plot(rf_15, col=colors_)

######## save classification image as geotiff ##########
classification_image <- writeRaster(rf_15,'RF15_s.tif','GTiff', overwrite=TRUE)
