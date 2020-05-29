## ----schedules/tempCurves--------------------------------------------------------------------------------------
schedule <- function(simHours) {
  simHours <- simHours %% 24
  #simHours <- round(simHours, digits=4)
  if (simHours == 7) return("breakStart")
  if (simHours > 7 & simHours <= 8) return("break")
  if (simHours > 8 & simHours < 9) return("class")
  if (simHours == 9) return("breakStart")
  if (simHours > 9 & simHours <= 9.2) return("break")
  if (simHours > 9.2 & simHours < 10.2) return("class")
  if (simHours == 10.2) return("breakStart")
  if (simHours > 10.2 & simHours <= 10.25) return("break")
  if (simHours > 10.25 & simHours < 11.25) return("class")
  if (simHours == 11.25) return("breakStart")
  if (simHours > 11.25 & simHours <= 11.5) return("break")
  if (simHours > 11.5 & simHours < 12.5) return("class")
  if (simHours == 12.5) return("breakStart")
  if (simHours > 12.5 & simHours <= 13.0) return("break")
  if (simHours > 13.00 & simHours < 14.00) return("class")
  if (simHours == 14) return("breakStart")
  if (simHours > 14.00 & simHours <= 14.2) return("break")
  if (simHours > 14.2 & simHours < 15.2) return("class")
  if (simHours == 15.2) return("breakStart")
  if (simHours > 15.2 & simHours <= 15.25) return("break")
  if (simHours > 15.25 & simHours < 16.25) return("class")
  if (simHours == 16.25) return("breakStart")
  if (simHours > 16.25 & simHours <= 18.00) return("break")
  else return("freeTime")
}

scheduleNumeric <- function(simHours) {
  simHours <- simHours %% 24
  if (simHours > 8 & simHours < 9) return(0)
  if (simHours == 9) return(1)
  if (simHours > 9 & simHours <= 9+1/6) return(1)
  if (simHours > 9+1/6 & simHours < 10+1/6) return(0)
  if (simHours == 10+1/6) return(1)
  if (simHours > 10+1/6 & simHours <= 10.25) return(1)
  if (simHours > 10.25 & simHours < 11.25) return(0)
  if (simHours == 11.25) return(1)
  if (simHours > 11.25 & simHours <= 11.5) return(1)
  if (simHours > 11.5 & simHours < 12.5) return(0)
  if (simHours == 12.5) return(1)
  if (simHours > 12.5 & simHours <= 13.0) return(1)
  if (simHours > 13.00 & simHours < 14.00) return(0)
  if (simHours == 14) return(1)
  if (simHours > 14.00 & simHours <= 14+1/6) return(1)
  if (simHours > 14+1/6 & simHours < 15+1/6) return(0)
  if (simHours == 15+1/6) return(1)
  if (simHours > 15+1/6 & simHours <= 15.25) return(1)
  if (simHours > 15.25 & simHours < 16.25) return(0)
  if (simHours == 16.25) return(1)
  if (simHours > 16.25 & simHours <= 16.5) return(1)
  else return(0)
}

# timesHour <- seq(8,18,1/60)
# scheduleplot <- qplot(timesHour, sapply(timesHour, scheduleNumeric), geom = "line", ylab = "", xlab="hour of the day",
#                       main = "Is water drawn from the system? (binary, school time schedule)")
# ggsave(filename = paste0("./plots/", version, "scheduleplot.png"), plot = scheduleplot, width = 12/2, height = 8/2, units = "in")

tempCurveAir <- function(simHours) {
  minT <- c(13.3, 13.2, 13.4, 13.6, 13.6, 12.7, 12.2, 12.8, 13.1, 13.1, 13.2, 13.2)
  maxT <- c(23.8, 23.8, 24, 23.5, 23.3, 23.7, 24.5, 25.3, 25.2, 24.2, 23.8, 23.6)

  T <- abs(mean(minT) - mean(maxT))/2 * sin((simHours-10) * pi/12) + mean(c(minT, maxT))
  return(T)
}

tempCurveSoil <- function(simHours) {
  minT <- c(13.3, 13.2, 13.4, 13.6, 13.6, 12.7, 12.2, 12.8, 13.1, 13.1, 13.2, 13.2)
  maxT <- c(23.8, 23.8, 24, 23.5, 23.3, 23.7, 24.5, 25.3, 25.2, 24.2, 23.8, 23.6)

  T <- 3 * sin((simHours-12) * pi/12) + mean(c(minT, maxT)) - 5
  return(T)
}

rainCurve <- function(simDay) {
  pm <- c(124, 127, 152, 181, 119, 31, 20, 47, 119, 153, 159, 132)/1000
  pd <- pm/c(31, 28, 31, 30, 31, 30, 31, 30, 31, 30, 31, 30)
  months <- seq(1,12,1)
  # plot(months, pd, type="l", ylim=c(0,max(pd)))

  pdSpline <- spline(months, pd, n = 365)
  # plot(pdSpline, type = "l")

  rain <- pdSpline$y
  # plot(rain, type = "l")
  return(rain[simDay])
}

# timesHour <- seq(0,24,10/60)
# tempdata <- as.data.frame(cbind(
#   timesHour,
#   tempAir = tempCurveAir(timesHour),
#   tempSoil = tempCurveSoil(timesHour)
# ))
#
# tempplot <- ggplot(tempdata, aes(timesHour)) +
#   geom_line(aes(y = tempSoil, col = "tempSoil"), size=1) +
#   geom_line(aes(y = tempAir, col= "tempAir"), size=1) +
#   scale_colour_manual(values=c(tempAir = "#68bec4", tempSoil = "#d36f65"))+
#   ggtitle("Temperature curves over the day") +
#   xlab ("hour of the day")
# ggsave(filename = paste0("./plots/", version, "tempplot.png"), plot = tempplot, width = 12/2, height = 8/2, units = "in")
#
# time <- seq(1,365,1)
# rainplot <- qplot(time, rainCurve()*1000, geom = "line", xlab = "simulation time (days)", ylab = "precipation in L/m^2",
#       ylim = c(0, max(rainCurve()*1000))) +
#   ggtitle("Rain precipation curve over the year")
# ggsave(filename = paste0("./plots/", version, "rainplot.png"), plot = rainplot, width = 12/2, height = 8/2, units = "in")
#
# rm(time, timesHour, tempdata, rainplot, scheduleplot, tempplot)

## ----parameters--------------------------------------------------------------------------------------

defineStartParameters <- function(h_0 = 1.0, A_roof = 500, h_tank = 5, r_tank = 3,
    material = "concrete", c_0 = 1.55 * 10^-4, T_water_0 = 17.0, h_air = 2.5, n_taps = 10, z = 3){
  basicParameters <- c(
    # I/O micro
    r_tank <- r_tank, # [m]
    h_0 <- h_0,
    # temperature
    h_air <- h_air, # [m]
    h_tank <- h_tank,  # [m]
    T_water_0 <- T_water_0, # [°C]
    # bacteria
    c_0 <- c_0) # [n/m^3]

  names(basicParameters) <-c("r_tank", "h_0", "h_air", "h_tank", "T_water_0", "c_0")

  if (material == "concrete") {
      parametersMaterial <- c(
          d_wall = 200/1000, # [m]
          rho_wall = 2400, # [kg/m^3] (concrete: 2400, polyethylen: 980)
          rho_water = 1000, # [kg/m^3]
          lambda_wall = 2.5, # [W/(m*K)] (concrete: 2.5, polyethylen: 0.5)
          lambda_water = 0.6, # [W/(m*K)]
          c_p_wall = 1000, # [J/(kg*K)] (concrete: 1000, polyethylen:1800)
          c_p_water = 4190# [J/(kg*K)]
      )
  } else if (material == "polyethylen"){
      parametersMaterial <- c(
          d_wall = 5/1000, # [m]
          rho_wall = 980, # [kg/m^3] (concrete: 2400, polyethylen: 980)
          rho_water = 1000, # [kg/m^3]
          lambda_wall = 0.5, # [W/(m*K)] (concrete: 2.5, polyethylen: 0.5)
          lambda_water = 0.6, # [W/(m*K)]
          c_p_wall = 1800, # [J/(kg*K)] (concrete: 1000, polyethylen:1800)
          c_p_water = 4190# [J/(kg*K)]
      )
  } else {
      print("wrong material name")
  }

  parameters <- c(basicParameters, parametersMaterial,
                  # I/O micro
                  g = 9.81, # [m/s^2]
                  n_taps = n_taps,
                  r_taps = 1/1000 * 1, # [m]
                  z = z, # [m]
                  #Q_in = 1/1000 * 23/60, # [m^3/s] (23 l/min)
                  #Q_in = min(rainCurve())*A_roof/24/60/60,
                  V_Bottle = 1/1000 * 0.5, # [m^3]
                  A_roof = A_roof,

                  # bacteria growth
                  V_0 = eval(h_0 * r_tank^2 * pi), # [m^3]
                  c_in = 1.55 * 10^-4, # [n/ml] -> [n/m^3]
                  k_20 = 0.504/ (24*60*60), # [day^-1] -> [s^-1]
                  Q_10 = 1.783,
                  T_20 = 20.0,

                  # temperature
                  h_soil = eval(max(h_tank - h_air), 0) # [m]

  )

  # calculate initial state (eval needed because of lazy execution)
  yini <- c(
    # I/O micro
    h = eval(h_0), # [m]
    Q_out = 0, # [m^3/s]
    n_Bottles = 0,
    V_out = 0,

    # bacteria growth
    c = eval(c_0), # [n/m^3]

    # temperature
    T_water = eval(T_water_0) # [°C]
  )

  return(list(yini = yini, parameters = parameters))
}

interactionPlot <- function(x, y1, y2, nameX, nameY1, nameY2, legendPosition){
  plot(x, y1, type="l", ylab="", xlab = "simulation time (hours)")
  par(new = TRUE)
  plot(x, y2, type = "l", axes = FALSE, bty = "n", xlab = "", ylab = "", col = "red")
  axis(side=4, at = pretty(range(y2)), col="red")
  legend(legendPosition, c(nameY1, nameY2), lty=c(1,1), lwd=c(2.5,2.5), col=c("black", "red"))
}

interactionPlot <- function(dataset, nameX, nameY1, nameY2, legendPosition){
  plot(dataset[[nameX]], dataset[[nameY1]], type="l", ylab="", xlab = "simulation time (hours)")
  par(new = TRUE)
  plot(dataset[[nameX]], dataset[[nameY2]], type = "l", axes = FALSE, bty = "n", xlab = "", ylab = "", col = "red")
  axis(side=4, at = pretty(range(dataset[[nameY2]])), col="red")
  legend(legendPosition, c(nameY1, nameY2), lty=c(1,1), lwd=c(2.5,2.5), col=c("black", "red"))
}
