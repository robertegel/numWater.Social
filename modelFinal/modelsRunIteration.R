modelRun <- function(parameters, yini, days, timestep = 1, method = euler, socialNorm = "default") {
  times <- seq(from = 0, to = 60*60*24*days, by = timestep)
  
  globEnv$waitingLine <- c()
  globEnv$waitingLineTime <- c()
  globEnv$servedList <- c()
  
  
  ## ----model-------------------------------------------------------------------------------------------
  model <- function(t, y, parameters) {
    with(as.list(c(y, parameters)), {
      simHours <- t/60/60 + 6
      simDays <- floor(simHours/24) %% 365 + 1
      
      #----I/O micro-------------------------------------------------------------------------------------------
      Q_in <- rainCurve(simDays) *A_roof/24/60/60# [m^3/(m^2 * day)] -> [m^3/s]
      dh <- (Q_in - Q_out)/(pi * r_tank^2)
      
      # test if there is a waiting line
      if (length(globEnv$waitingLine) > 0) {
        # decrease the number of taps if there is no waiting line -> no line, no people who open water taps
        n_taps <- min(n_taps, length(globEnv$waitingLine))
        
        if (schedule(simHours) == "break") {
          newQ_out <- n_taps * pi * r_taps^2 * sqrt(2 * g) * (h + z)^(1/2)

          firstInLine <- globEnv$waitingLine[1:n_taps]
          globEnv$people$bottleFill[firstInLine] = globEnv$people$bottleFill[firstInLine] + 
            newQ_out * 1000 * timestep() / n_taps  # * 1000 because [m^3] -> [l]
        } else if (schedule(simHours) == "breakStart"){
          # (start of school break)
          newQ_out <- n_taps * pi * r_taps^2 * sqrt(2 * g) * (h + z)^(1/2)
          
          if (socialNorm == "egoistic") {
            # shuffle waiting line (egoistic behavior)
            globEnv$waitingLine <- sample(globEnv$waitingLine)
          } else if (socialNorm == "altruistic") {
            # get bottlefill from people in waiting line
            waitingLineBottleFill <- globEnv$people$bottleFill[globEnv$waitingLine]
            # sort waiting line (lowest bottle fill first, altruistic behavior)
            globEnv$waitingLine <- globEnv$waitingLine[order(waitingLineBottleFill)]
          } else if (socialNorm == "default"){
            # do nothing
          }
          
          firstInLine <- globEnv$waitingLine[1:n_taps]
          globEnv$people$bottleFill[firstInLine] = globEnv$people$bottleFill[firstInLine] + 
            newQ_out * 1000 * timestep() / n_taps  # * 1000 because [m^3] -> [l]
        } else if (schedule(simHours) == "class" | schedule(simHours) == "freeTime") {
          # no outflow (school class)
          newQ_out <- 0
          n_taps <- 0
        }
  
      } else {
        # decrease the number of taps if there is no waiting line -> no line, no people who open water taps
        n_taps <- 0
        # no outflow (no waiting line)
        newQ_out <- 0
      }

      # if tank full no change in water height
      if (h >= h_tank & dh >= 0){
        dh <- 0
      }
      
      # if tank empty set outflow = inflow, no change in water height
      if (h <= 0 & dh <= 0){
        dh <- 0
        newQ_out <- Q_in
      }
      
      dn_Bottles <- 0 # set to zero, gets increased when removing someone from waiting line
      dV_out <- newQ_out

      V <- max(h * r_tank^2 * pi, 0.0002)

      #----temperature-------------------------------------------------------------------------------------------
      T_air <- tempCurveAir(simHours)
      T_soil <- tempCurveSoil(simHours)

      R_ia_bottom    <- d_wall /(lambda_wall * pi * r_tank^2)
      R_ia_side_soil <- d_wall /(lambda_wall * 2 * pi * r_tank * h_soil)
      R_ia_side_air  <- d_wall /(lambda_wall * 2 * pi * r_tank * h_air)
      R_ia_top       <- d_wall /(lambda_wall * pi * r_tank^2)

      c_i_bottom     <- c_p_water * rho_water * pi * r_tank^2 * h_tank + c_p_wall * rho_wall * d_wall * pi * r_tank^2
      c_i_side_soil  <- c_p_water * rho_water * pi * r_tank^2 * h_tank + c_p_wall * rho_wall * d_wall * 2 * pi * r_tank * h_soil
      c_i_side_air   <- c_p_water * rho_water * pi * r_tank^2 * h_tank + c_p_wall * rho_wall * d_wall * 2 * pi * r_tank * h_air
      c_i_top        <- c_p_water * rho_water * pi * r_tank^2 * h_tank + c_p_wall * rho_wall * d_wall * pi * r_tank^2

      dT_water_conduction <- (T_soil-T_water)/(R_ia_bottom * c_i_bottom) +
        (T_soil-T_water)/(R_ia_side_soil * c_i_side_soil) +
        (T_air-T_water)/(R_ia_side_air * c_i_side_air) +
        (T_air-T_water)/(R_ia_top * c_i_top)

      dT_water_pollution <- ((Q_in * T_air + V * T_water - Q_out * T_water)/(V + Q_in - Q_out)) - T_water

      dT_water <- dT_water_conduction + dT_water_pollution
      
      if (abs(dT_water) > 10){
        dT_water <- 0
      }
      
      ##----bacterial growth-------------------------------------------------------------------------------------------
      k <- k_20 * Q_10^((T_water - T_20)/10)

      dc <- ((Q_in * c_in + V * c - Q_out *c)/(V + Q_in - Q_out)) - c + (k * c)
      #dc <- (k * c)

      if (abs(dc) > c/5){
        dc <- 0
      }
      
      # people
      n_people <- nrow(globEnv$people)
      
      bottleFill <- globEnv$people$bottleFill
      satisfied <- globEnv$people$satisfied
      VBottle <- globEnv$people$VBottle
      waterUsePerSec <- globEnv$people$waterUsePerSec
      ID <- globEnv$people$ID
      
      # drink from bottle if not empty
      max0 <- function(x) max(x,0) 
      bottleFill <- sapply(FUN = max0, bottleFill - waterUsePerSec * timestep())
      emptyBottlesUndocumented <- which(bottleFill == 0 & satisfied == TRUE)
      satisfied[emptyBottlesUndocumented] <- FALSE
      
      # might crash because firstInLine==NULL
      if (exists("firstInLine")) {
        # remove first in line from waiting line if bottle full, set bottleFill to VBottle
        for (i in 1:length(firstInLine)){
          if (bottleFill[firstInLine[i]] > VBottle[firstInLine[i]]) {
            # remove from waiting line
            globEnv$waitingLine <- globEnv$waitingLine[-i]
            # set bottleFill to VBottle
            bottleFill[firstInLine[i]] <- VBottle[firstInLine[i]]
            # add to servedList and increase dn_Bottles by 1
            globEnv$servedList <- rbind(globEnv$servedList,
                                        cbind(ID = firstInLine[i], t))
            dn_Bottles =+ 1
          }
        }
      }
      
      # add to waiting line if bottle almost empty, if not already waiting
      almostEmptyUndocumented <- which(bottleFill <= 0.25 & !ID %in% globEnv$waitingLine)
      
      if (length(almostEmptyUndocumented) > 0) {
        globEnv$waitingLine <- c(globEnv$waitingLine, almostEmptyUndocumented)
        globEnv$waitingLineTime <- rbind(globEnv$waitingLineTime,
                                         cbind(ID = almostEmptyUndocumented, t))
      }
    

      # update people data   
      globEnv$people$bottleFill <- bottleFill
      globEnv$people$satisfied <- satisfied
      satisfactionRate <- as.numeric(summary(satisfied)["TRUE"])/n_people

      newh <- as.numeric(h + dh)
      newn_Bottles <- as.numeric(dn_Bottles + n_Bottles)  
      newV_out <- as.numeric(dV_out + V_out)
      newc <- as.numeric(dc + c)
      newT_water <- as.numeric(dT_water + T_water)
      
      # return everything
        return(list(c(newh, newQ_out, newn_Bottles, newV_out, newc, newT_water), 
                    bottleFill1 = globEnv$people$bottleFill[1],
                    bottleFill2 = globEnv$people$bottleFill[2],
                    bottleFill3 = globEnv$people$bottleFill[3],
                    bottleFill4 = globEnv$people$bottleFill[4], 
                    n_taps = as.numeric(n_taps), 
                    satisfactionRate = satisfactionRate,
                    waitingLineLength = as.numeric(length(globEnv$waitingLine))
        ))
      }
    )
  }

## -solver---------------------------------------------------------------------------------------------------
out <- ode(func = model, y = yini, times = times, parms = parameters, method = "iteration")

return(out)
}