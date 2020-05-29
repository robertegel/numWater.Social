## ----setup, include=FALSE----------------------------------------------------------------------------
# if not installed yet, install required packages
list.of.packages <- c("ggplot2", "deSolve", "progress", "parallel", "doSNOW", "cowplot", "abind", "tidyr", "tgp", "hrbrthemes", "powdist", "corrplot")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

# if (exists("cl")) {
#   rm(list=ls()[-(which(ls() == "cl"))])
# } else {
#   rm(list=ls())
# }

# library for simulations
library(deSolve)

# libraries for parallel computing
library(parallel)
library(doSNOW)

# library for progress bar
library(progress)

# library for binding multidimensional arrays/data transformation
library(abind)
library(tidyr)

# libraries for plotting
library(ggplot2)
library(cowplot)
library(hrbrthemes)
library(corrplot)

# source external file to define helper functions
# for schedule, temperature and rain curve, parameters
source("./schedules.climate.parameters.R")
source("./modelsRunIteration.R")

## -run models---------------------------------------------------------------------------------------------------
days <- 0.5
timestep <- 5

n_people = 2000

variationssocialNorm <- c("default", "altruistic", "egoistic")

numCores <- detectCores()
if(!exists("cl")) cl <- makeCluster(numCores)
registerDoSNOW(cl)

progress <- function(i) pb$tick()
pb <- progress_bar$new(
  format = "[:bar] :current/:total runs | elapsed::elapsed",
  total = length(variationssocialNorm), clear = FALSE)
opts <- list(progress=progress)
bind3d <- function(...) abind(..., along = 3)

version <- paste0("version4.1.socialNorm.", timestep, "secSteps")

start <- Sys.time()
out <-foreach(socialNorm=iter(variationssocialNorm), .options.snow=opts, .packages = c("deSolve")) %dopar% {
  set.seed(5)
  
  people <- data.frame(ID = 1:n_people)
  # random water use per second
  people$waterUsePerSec <- rnorm(n_people, mean = 2, sd = 0.5) /24/60/60
  # random size of bottle
  people$VBottle <- sample(x = c(0.5, 0.75, 1.0, 1.5), size = n_people, 
                           prob = c(0.3, 0.25, 0.35, 0.1), replace = TRUE)
  # initial random bottle fill (required >= 0)
  people$bottleFill <- as.numeric(Map(f= max, rnorm(n_people, mean = 0.5, sd = 0.1), 0)) * people$VBottle  
  # initial satisfaction (becomes FALSE if bottleFill reaches zero)
  people$satisfied <- replicate(n = n_people, TRUE)
  
  # write to new environment (works better for use inside functions)
  globEnv <- new.env()
  globEnv$people <- people
  
  startParameters <- defineStartParameters()

  modelRun(parameters = startParameters$parameters, yini = startParameters$yini, 
           days = days, timestep =timestep, socialNorm = socialNorm)
}
print(Sys.time() - start)

outData <- data.frame()

for (i in 1:length(out)) {
  simHours <- eval(out[[i]][,"time"] / 60/60 + 6)
  tmp <- as.data.frame(out[[i]][,])
  tmp$socialNorm <- as.factor(c(variationssocialNorm[i]))
  tmp$simHours <- simHours
  outData <- rbind(outData, tmp)
  
  # bot <- diff(out[[i]][,"n_Bottles"][seq(1,length(out[[i]][,1] -1), by=288)])
  # tmp <- data.frame(simHours = 1:hours)
  # tmp$n_Bottles = bot
  tmp$socialNorm <- as.factor(c(variationssocialNorm[i]))
  # bottlesPerDay <- rbind(bottlesPerDay, tmp)
}

## -plots---------------------------------------------------------------------------------------------------
{
  h.plot <- ggplot(outData, aes(simHours, h, group=socialNorm)) +
    geom_line(size = 0.5, aes(colour = socialNorm)) +
    ylab("water height inside the tank (h)") + 
    scale_x_continuous(name = "simulation time in hours", 
                       breaks = c(6, 9, 12, 15, 18), labels = function(x) {paste0(x, "h")}) +
    scale_color_brewer() +
    scale_fill_ipsum() +
    theme_ipsum_ps(grid="XY", axis="xy") + theme(legend.position="none")
  
  n_Bottles.plot <- ggplot(outData, aes(x = simHours, y = n_Bottles, group = socialNorm)) +
    geom_line(size = 0.5, aes(colour = socialNorm)) +
    ylab("number of bottles drawn from system") + 
    scale_x_continuous(name = "simulation time in hours", 
                       breaks = c(6, 9, 12, 15, 18), labels = function(x) {paste0(x, "h")}) +
    scale_color_brewer() +
    scale_fill_ipsum() +
    theme_ipsum_ps(grid="XY", axis="xy") + theme(legend.position="none")
  
  Q_out.plot <- ggplot(outData, aes(x = simHours, y = Q_out, group = socialNorm)) +
    geom_line(size = 0.5, aes(colour = socialNorm)) +
    ylab("Outflow (Q_out)") + 
    scale_x_continuous(name = "simulation time in hours", 
                       breaks = c(6, 9, 12, 15, 18), labels = function(x) {paste0(x, "h")}) +
    scale_color_brewer() +
    scale_fill_ipsum() +
    theme_ipsum_ps(grid="XY", axis="xy") + theme(legend.position="none")
  
  satisfactionRate.plot <- ggplot(outData, aes(x = simHours, y = satisfactionRate, group = socialNorm)) +
    geom_line(size = 0.5, aes(colour = socialNorm)) +
    ylab("rate of satisfaction") + 
    scale_x_continuous(name = "simulation time in hours", 
                       breaks = c(6, 9, 12, 15, 18), labels = function(x) {paste0(x, "h")}) +
    scale_color_brewer() +
    scale_fill_ipsum() +
    theme_ipsum_ps(grid="XY", axis="xy") + theme(legend.position="none")
  
  waitingLineLength.plot <- ggplot(outData, aes(x = simHours, y = waitingLineLength, group = socialNorm)) +
    geom_line(size = 0.5, aes(colour = socialNorm)) +
    ylab("people standing in waiting line") + 
    scale_x_continuous(name = "simulation time in hours", 
                       breaks = c(6, 9, 12, 15, 18), labels = function(x) {paste0(x, "h")}) +
    scale_color_brewer() +
    scale_fill_ipsum() +
    theme_ipsum_ps(grid="XY", axis="xy") + theme(legend.position="none")
  
  n_taps.plot <- ggplot(outData, aes(x = simHours, y = n_taps, group = socialNorm)) +
    geom_line(size = 0.5, aes(colour = socialNorm)) +
    ylab("number of opened water taps") + 
    scale_x_continuous(name = "simulation time in hours", 
                       breaks = c(6, 9, 12, 15, 18), labels = function(x) {paste0(x, "h")}) +
    scale_color_brewer() +
    scale_fill_ipsum() +
    theme_ipsum_ps(grid="XY", axis="xy") + theme(legend.position="none")

  gglegend <- get_legend(
    ggplot(outData, aes(simHours, c, group=socialNorm)) +
      geom_line(size = 0.5, aes(colour = socialNorm)) +
      xlab("simulation time in hours") + 
      scale_color_brewer() +
      scale_fill_ipsum() +
      theme_ipsum_ps(grid="XY", axis="xy") + theme(legend.position="bottom")
  )
  
  plotgrid <- plot_grid(h.plot, n_Bottles.plot, 
                        satisfactionRate.plot, Q_out.plot, waitingLineLength.plot, n_taps.plot, ncol = 2)
  plotgrid_legend <- plot_grid(plotgrid, gglegend,  ncol = 1,  rel_heights = c(1,0.05))
  plotgrid_legend
  ggsave2(paste0("./plots/",version,".jpeg"), plot = plotgrid_legend, width = 12, height = 12, units = "in")
}

par(mfrow = c(1,1))
for (socialNorm in variationssocialNorm) {
  png(filename = paste0("./plots/varsocialNorm/", version, "-", socialNorm, ".png"), 
      width = 1500, height = 1200, res = 150)
  # filter outData for specific socialNorm
  out.tmp <- outData[which(outData$socialNorm == socialNorm), ]
  # bind interesting variables in 
  tmp <- data.frame(satisfaction = out.tmp$satisfactionRate, waitingLine = out.tmp$waitingLineLength,
               h=out.tmp$h, Q_out=out.tmp$Q_out, n_taps = out.tmp$n_taps, 
               V_out = out.tmp$V_out, n_Bottles = out.tmp$n_Bottles)
  tmp.cor <- cor(tmp)
  tmp.corplot <- corrplot.mixed(tmp.cor, lower = "number", upper = "square", tl.col = "black", 
                                cl.align.text ="l", na.label = "o")
  dev.off()
}

stopCluster(cl)
rm(cl)
