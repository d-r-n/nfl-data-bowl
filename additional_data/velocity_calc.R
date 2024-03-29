library(devtools)
library(dplyr)
library(gganimate)
library(ggforce)
library(ggplot2)
library(readr)

files <- list.files(path="Documents/GitHub/APM-Term-Project/additional_data/team_plays/",
                    pattern = "*_plays.csv", full.names = T)

#ARI_plays <- read_csv("Documents/GitHub/APM-Term-Project/additional_data/team_plays/ARI_plays.csv", 
#                      col_types = cols(X1 = col_skip()))

#myfiles <- lapply(files, function(i){
#  read.csv(i, header=TRUE)
#})


velocities <- setNames(data.frame(matrix(ncol=8, nrow=0)), c("gameId", "playId", "nflId", "frame","x", "y", "v_x", "v_y"))
#unique_games <- ARI_plays %>% unique(c=("gameId"))
for (x in files[1]){
  i <- read_csv(x,col_types = cols(X1 = col_skip()))
  unique_games <- i %>% unique(c=("gameId"))
  for (val in unique_games) {
    plays <- i %>% filter(gameId == val)
    unique_plays <- unique(plays$playId)
    for (play in unique_plays) {
      df <- i %>% filter(gameId == val, playId == play)
      frames <- unique(df$frame)
      # * get play metadata ----
      play_dir <- df$playDirection %>% .[1]
      yards_togo <- df$yardsToGo %>% .[1]
      los <- df$absoluteYardlineNumber %>% .[1]
      togo_line <- if(play_dir=="left") los-yards_togo else los+yards_togo
      first_frame <- df %>%
        filter(event == "line_set" | event == "ball_snap") %>% 
        distinct(frame) %>% 
        slice_max(frame) %>% 
        pull()
      final_frame <- df %>% 
        filter(event == "tackle" | event == "touchdown" | event == "out_of_bounds" | event == 'pass_outcome_incomplete' | event == "pass_outcome_interception") %>% 
        distinct(frame) %>% 
        slice_max(frame) %>% 
        pull()
      # * separate player and ball tracking data ----
      player_data <- df %>% 
        filter(between(frame, first_frame, final_frame)) %>% 
        select(gameId, playId, frame, homeTeamFlag, nflId, teamAbbr, displayName, jerseyNumber, position, positionGroup,
               x, y, s, o, dir, event) %>% 
        filter(displayName != "Football")
      #  velocity angle in radians
      player_data$dir_rad <- player_data$dir * pi / 180
      #  velocity components
      player_data$v_x <- sin(player_data$dir_rad) * player_data$s
      player_data$v_y <- cos(player_data$dir_rad) * player_data$s
      # adding data to "velocities" dataframe
      #vector <- c(player_data$nflId, player_data$v_x, player_data$v_y)
      velocities1 <- player_data[,c("gameId", "playId", "nflId", "frame","x", "y", "v_x", "v_y")]
      velocities <- rbind(velocities, velocities1)
    }
  }

  write_csv(velocities, "Documents/GitHub/APM-Term-Project/additional_data/team_plays/velocities.csv")
} 

