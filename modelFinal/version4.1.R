## ----setup, include=FALSE----------------------------------------------------------------------------
# if not installed yet, install required packages
list.of.packages <- c("ggplot2", "deSolve", "progress", "parallel", "doSNOW", "cowplot", "abind", "tidyr", "tgp", "hrbrthemes", "powdist")
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

# source external file to define helper functions
# for schedule, temperature and rain curve, parameters
source("./schedules.climate.parameters.R")
source("./modelsRunIteration.R")

## -run models---------------------------------------------------------------------------------------------------
days <- 0.5
timestep <- 5

n_people = 2000
socialNorm <- "default"

version <- paste0("version4.1.", socialNorm, ".", timestep, "secSteps")

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

startParameters <- defineStartParameters(h_0 = 1.0, A_roof = 500)
system.time(out <- modelRun(parameters = startParameters$parameters, yini = startParameters$yini, 
                            days = days, timestep = timestep, socialNorm = socialNorm))

summary(globEnv$people)

## -plots---------------------------------------------------------------------------------------------------
{
  times <- out[,"time"]
  simHours <- eval(times / 60/60 + 6)
  data <- as.data.frame(out)
  data$simHours <- simHours
  data$bactAmount <- data[, "c"]*data[, "h"]*pi*startParameters$parameters["r_tank"]^2
  
  par(mfrow = c(2, 2))
  plot(data$simHours, data$bottleFill1, type = "l")
  lines(x = c(0,100000), y = replicate(n = 2, globEnv$people$VBottle[1]))
  plot(data$simHours, data$bottleFill2, type = "l")
  lines(x = c(0,100000), y = replicate(n = 2, globEnv$people$VBottle[2]))
  plot(data$simHours, data$bottleFill3, type = "l")
  lines(x = c(0,100000), y = replicate(n = 2, globEnv$people$VBottle[3]))
  plot(data$simHours, data$bottleFill4, type = "l")
  lines(x = c(0,100000), y = replicate(n = 2, globEnv$people$VBottle[4]))
  plot(simHours, data$n_taps, type = "l", ylab = "n_taps", xlab = "simulation time")
}

{
  h.plot <- ggplot(data, aes(simHours, h)) +
    geom_line(size = 0.5) +
    ylab("water height inside the tank (h)") + 
    scale_x_continuous(name = "simulation time in hours", 
                       breaks = c(6, 9, 12, 15, 18), labels = function(x) {paste0(x, "h")}) +
    scale_color_ipsum() +
    scale_fill_ipsum() +
    theme_ipsum_ps(grid="XY", axis="xy") + theme(legend.position="none")
  
  Q_out.plot <- ggplot(data, aes(simHours, Q_out)) +
    geom_line(size = 0.5) +
    ylab("Outflow (Q_out)") + 
    scale_x_continuous(name = "simulation time in hours", 
                       breaks = c(6, 9, 12, 15, 18), labels = function(x) {paste0(x, "h")}) +
    scale_color_ipsum() +
    scale_fill_ipsum() +
    theme_ipsum_ps(grid="XY", axis="xy") + theme(legend.position="none")
  
  n_Bottles.plot <- ggplot(data, aes(simHours, n_Bottles)) +
    geom_line(size = 0.5) +
    ylab("number of bottles drawn from system") + 
    scale_x_continuous(name = "simulation time in hours", 
                       breaks = c(6, 9, 12, 15, 18), labels = function(x) {paste0(x, "h")}) +
    scale_color_ipsum() +
    scale_fill_ipsum() +
    theme_ipsum_ps(grid="XY", axis="xy") + theme(legend.position="none")
 
  satisfactionRate.plot <- ggplot(data, aes(simHours, satisfactionRate)) +
    geom_line(size = 0.5) +
    ylab("rate of satisfaction") + ylim(c(min(data$satisfactionRate), 1)) +
    scale_x_continuous(name = "simulation time in hours", 
                       breaks = c(6, 9, 12, 15, 18), labels = function(x) {paste0(x, "h")}) +
    scale_color_ipsum() +
    scale_fill_ipsum() +
    theme_ipsum_ps(grid="XY", axis="xy") + theme(legend.position="none")
  
  waitingLineLength.plot <- ggplot(data, aes(simHours, waitingLineLength)) +
    geom_line(size = 0.5) +
    ylab("people standing in waiting line") + 
    scale_x_continuous(name = "simulation time in hours", 
                       breaks = c(6, 9, 12, 15, 18), labels = function(x) {paste0(x, "h")}) +
    scale_color_ipsum() +
    scale_fill_ipsum() +
    theme_ipsum_ps(grid="XY", axis="xy") + theme(legend.position="none")
  
  n_taps.plot <- ggplot(data, aes(simHours, n_taps)) +
    geom_line(size = 0.5) +
    ylab("number of opened water taps") + 
    scale_x_continuous(name = "simulation time in hours", 
                       breaks = c(6, 9, 12, 15, 18), labels = function(x) {paste0(x, "h")}) +
    scale_color_ipsum() +
    scale_fill_ipsum() +
    theme_ipsum_ps(grid="XY", axis="xy") + theme(legend.position="none")
  
  plotgrid <- plot_grid(h.plot, n_Bottles.plot, 
                        satisfactionRate.plot, Q_out.plot, waitingLineLength.plot, n_taps.plot, ncol = 2)
  plotgrid
  ggsave2(paste0("./plots/",version,".jpeg"), plot = plotgrid, width = 12, height = 12, units = "in")
    
}
