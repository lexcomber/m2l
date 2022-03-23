## This code demonstrates the approach described in proposal 
## led by Lex Comber and Paul Harris to the Moelcules to Landscapes call
## Please contact Lex with any questions (a.comber@leeds.ac.uk)

## All data files should be in the same working directory as the script

## Part 0: load packages and data, set the data up
# 1.1 test for installed packahges and install if not present 
if (!is.element("sf", installed.packages()))
    install.packages("sf", dep = T)
if (!is.element("tidyverse", installed.packages()))
    install.packages("tidyverse", dep = T)
if (!is.element("gstat", installed.packages()))
    install.packages("gstat", dep = T)
if (!is.element("terra", installed.packages()))
    install.packages("terra", dep = T)
if (!is.element("raster", installed.packages()))
    install.packages("raster", dep = T)
if (!is.element("intamap", installed.packages()))
    install.packages("intamap", dep = T)
library(sf)
library(tidyverse)
library(gstat)
library(terra)
library(raster)
library(intamap)

## Part 1 Load and set up the data
# 1.1 load the field and environmental gradient data
setwd("/Users/geoaco/Desktop/my_docs_mac/leeds_work/research/NERC_mol2land/nwfp_data/")
nwG = st_read("nwG.gpkg")
eg <- rast("eg.tif")
# convert eg to sp format
eg.spdf = as(raster(eg), "SpatialPointsDataFrame")
# 1.2 make a sampling grid
gr = st_make_grid(nwG, 10, what = "centers", square = T)
gr = st_transform(gr, 27700)
df = data.frame(ID = 1:length(gr))
# make spatial
gr = st_as_sf(df, gr)
gr = gr[nwG,]
# add ID
gr$ID = 1:nrow(gr)
rownames(gr) = 1:nrow(gr)
# 1.3 extract data for grid, convert to sp format (for kriging)
v = vect(gr)
crs(v) = crs(eg)
e <- extract(eg, v)
gr %>% inner_join(e) -> gr
gr_sp = as(gr, "Spatial")
# 1.4 find existing (fixed) sample locations (in field centres)
field_centres = st_centroid(nwG)
f = vector()
for(j in 1:7){
	st_dists.j = st_distance(gr, field_centres[j,])
	f = c(f, which.min(st_dists.j))
}

## Part 2 Define T&B function
# 2.1 helper function - works like rowSums and colSums
rowMins <- function(x) apply(x,1,min)  
# 2.2 the function to be minimised - d is a distance matrix
pm.objective <- function(x,d) sum(rowMins(d[,x])) 
# 2.3 TB wrapper	
tb.m <- function(x = 7, d = d.i, fixed = f) {
	x = 7
	choices <- 1:nrow(d)
	if (length(fixed) > 0) {
		choices = choices[-fixed]
	} 
	if (length(x) == 1) {
        x <- sample(choices, x)
    }
    this = x
	count = 0
	repeat {
		update = tb.cycle.m(this,d,fixed)
		count <- count+1
		cat(count)
		#cat(update)
		if (all(this == update)) break
		this = update}
	return(this) }
# 2.4 TB engine
tb.cycle.m <- function(x = this,d, fixed = NULL) {
    rest = setdiff(1:nrow(d),c(x, fixed))
	best = pm.objective(c(x, fixed),d)
	this = x
	best.i = NULL
	best.j = NULL
	for (i in 1:length(x)) {
		for (j in 1:length(rest)) {
			probe = this
			probe[i] = rest[j]
			score = pm.objective(c(probe, fixed),d)
			if (score < best) {
				best.i = i
				best.j = j 
				break } }
			if (score < best ) break }
	if (! is.null(best.j)) this[best.i] = rest[best.j]
	return(this)}

## Part 3 Variograms for environmental gradient interpolated variance
# 3.1 create the estimated variogram 
# needed for weighted least squares variogram model fit paramters 
var.est <- variogram(eg~1,gr_sp)
nugget.start.i <- var.est.i$gamma[1]
sill.start.i <- mean(var.est.i$gamma)/2
range.start.i <- (st_bbox(nwG)["xmax"] - st_bbox(nwG)["xmin"])/2
nugget.heuristic.i <- 0
# 3.2 weighted least squares fit model
var.mod.i <- fit.variogram(var.est.i,
		vgm(sill.start.i,"Exp",range.start.i,nugget=nugget.start.i),
		fit.sills=c(T,T),fit.ranges=T)
# 3.3 kriging with the variogram model paramters
kriged.i = yamamotoKrige(eg~1, gr_sp, gr_sp, var.mod.i)
# convert to sf and clip
sample_locs.i = st_as_sf(kriged.i)
st_crs(sample_locs.i) = crs(nwG)
# clip to extent
sample_locs.i = sample_locs.i[nwG, ]

## Part 4 Find best n locations 
## Sections 4.1 and 4.2 take some hours to run
## the results have been saved into a file that can be loaded
## uncomment the line below to do this and don't run the rest of this section
# load("res.i.RData")

## 4.1 unweighted by EG with and without existing sample locations
# create distance matrix
d.i <- as.matrix(dist(st_coordinates(gr)))
# plot(Var.est, model = Var.mod,
locs_dist_f.i = tb.m(x = 7, d.i, fixed = f)
locs_dist.i = tb.m(x = 7, d.i, fixed = NULL)

## 4.2 weighted by EG with and without existing sample locations
# weight the distance matrix by the interpolated variance
d2.i = d.i * sample_locs.i$var1.var
locs_dist_w_f.i = tb.m(x = 7, d2.i, fixed = f)
locs_dist_w.i = tb.m(x = 7, d2.i, fixed = NULL)

## 4.3 list and save	
res.i = list(gr, f, locs_dist.i, locs_dist_f.i, locs_dist_w.i, locs_dist_w_f.i)
names.i = c("gr", "f", "unw", "unwf", "w", "wf")
names(res.i) = names.i
save(res.i, file = "res.i.RData")

## Part 5 plots
# 5.1 # Figure 1 Env gradient
ggplot() + 
	geom_sf(data = gr, aes(col = eg), shape = 15) +					
	scale_colour_viridis_c(option="B", 
		name = "Environmental \nGradient", direction = -1) +
	geom_sf(data = nwG, colour="black", fill=NA) +
	coord_sf(datum=st_crs(27700)) + theme_bw() +
	theme(axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank(), 
          axis.title.y=element_blank(),
          axis.text.y=element_blank(),
          axis.ticks.y=element_blank(),
          legend.position = "bottom", 
          text=element_text(size=15))

# 5.2 # Fig 2 Interpolation variance
# rescale the interpolation variance
sample_locs.i$int_var = sample_locs.i$var1.var *10e14
ggplot() + 
	geom_sf(data = sample_locs.i, aes(col = int_var), shape = 15) +	
	scale_colour_viridis_c(option="D", 
		name = "Interpolation \nVariance (rescaled)",
		direction = -1) +
	geom_sf(data = nwG, colour="black", fill=NA) +
	coord_sf(datum=st_crs(27700)) + theme_bw() +
	theme(axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank(), 
          axis.title.y=element_blank(),
          axis.text.y=element_blank(),
          axis.ticks.y=element_blank(),
          legend.position = "bottom", 
          text=element_text(size=15))

# 5.3 Fig 3 selected locations weighted, with exisiting (fixed) samples
# create a layer of existing and selected points 
selected = gr[res.i$wf,] 
selected$Geosample = "Optimised"
selected$cols = "red"
fixed = gr[f,] 
fixed$Geosample = "Existing" 
fixed$cols = "black"
tmp = rbind(selected, fixed)
cols =  tmp$cols
names(cols) = tmp$Geosample
ggplot() + 
	geom_sf(data = gr, col = "darkgrey", size = 0.5) +
	geom_sf(data = nwG, colour="black", fill=NA) +
	geom_sf(data = tmp, aes(col = Geosample), size = 2)	+
	scale_colour_manual(values = cols, name = "Geosample \nwith Existing") +
	coord_sf(datum=st_crs(27700)) + theme_bw() +
	theme(axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank(), 
          axis.title.y=element_blank(),
          axis.text.y=element_blank(),
          axis.ticks.y=element_blank(),
          legend.position = "bottom", 
          text=element_text(size=15))

# 5.4 Fig 4 selected locations without fixed
tmp = gr[res.i$w,] 
tmp$Geosample = "Optimised"
tmp$cols =  "red"
cols =  tmp$cols
names(cols) = tmp$Geosample

ggplot() + 
	geom_sf(data = gr, col = "darkgrey", size = 0.5) +
	geom_sf(data = nwG, colour="black", fill=NA) +
	geom_sf(data = tmp, aes(col = Geosample), size = 2)	+
	scale_colour_manual(values = cols, name = "Geosample \n(No Existing)") +
	coord_sf(datum=st_crs(27700)) + theme_bw() +
	theme(axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank(), 
          axis.title.y=element_blank(),
          axis.text.y=element_blank(),
          axis.ticks.y=element_blank(),
          legend.position = "bottom", 
          text=element_text(size=15))


### END
	  
	  