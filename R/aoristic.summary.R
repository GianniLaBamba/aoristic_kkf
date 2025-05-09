#' Summarize weekly aoristic weights
#'
#' Summarizes the sum of aoristic weights for each hour of the week, based on output from an aoristic data 
#' frame (created by aoristic.df). The function returns a data frame, with optional outputs. 
#' Option 'xlsx' sends the data frame to an Excel spreadsheet in the current working directory. 
#' Filenames increment to prevent overwriting previous analyses. Using option 'jpg' 
#' creates a color coded summary table in jpg format in the working directory.
#' The filename is aoristic_distribution.jpg, adding incremental numbers as necessary to the filename.
#'  
#' NOTE: Be aware that the distribution of values is NOT the same as the aoristic.ref() output, because
#' the summary charts and graphs move Sunday to the end of the week to keep the weekend together.
#' 
#' @param data1 a data frame output from the aoristic.df function
#' @param output output ='xlsx' for an Excel format output
#' #' output ='jpg' for JPG grid, blank otherwise
#' @return A data frame with aoristic values summed for each hour of the week
#' @importFrom grDevices dev.list dev.off jpeg 
#' @examples 
#' \dontrun{
#' 
#' aor.summary <- aoristic.summary(aor.df)
#' aor.summary <- aoristic.summary(aor.df, 'xlsx')
#' aor.summary <- aoristic.summary(aor.df, 'jpg')
#' }
#' @import scales tidyr ggplot2 dplyr 
#' @export
#' @references Ratcliffe, J. H. (2002). Aoristic signatures and the spatio-temporal analysis of high volume crime patterns. Journal of Quantitative Criminology, 18(1), 23-43.


aoristic.summary <- function (data1, output = ""){

# Create the output data frame --------------------------------------------

    df3 <- data.frame(matrix(0, ncol = 7, nrow = 24))
    output.row <- 1
    output.col <- 1
    f <- the.hour <- the.day <- rat.hour <- NULL


    for (k in 1:168)  # Sum the column values for each hour of the week
    {
      cur.column.name <- paste("hour", k, sep = "")
      z <- sum(as.numeric(data1[ ,cur.column.name]), na.rm = TRUE)

      df3[output.row,output.col] <-  trimws(format(round(z, 3), nsmall=3)) # Assign value to cell

          output.row <- output.row + 1
      if (output.row == 25) {
        output.row <- 1
        output.col <- output.col + 1
      }
    }

    colnames(df3) <- c('So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa')
    Range <- c('0000-0059',  '0000-0159',  '0200-0259',  '0300-0359',  '0400-0459',  '0500-0559',
                     '0600-0659',  '0700-0759',  '0800-0859',  '0900-0959',  '1000-1059',  '1100-1159',
                     '1200-1259',  '1300-1359',  '1400-1459',  '1500-1559',  '1600-1659',  '1700-1759',
                     '1800-1859',  '1900-1959',  '2000-2059',  '2100-2159',  '2200-2259',  '2300-2359' )
    df4 <- data.frame(Range)
    df4 <- data.frame(df4,df3)
    df4 <- df4[, c(1, 3, 4, 5, 6, 7, 8, 2)] # Reorder columns to put weekend at the end
    rm(df3)
    for (j in 2:8){# recode hours as numeric
      df4[ ,j] <- as.numeric(df4[, j])
    }
    
    
    

# Optional outputs --------------------------------------------------------
    
    # EXCEL OUTPUT: Switch output='xlsx'
    if (output == "xlsx")
    {
        current.folder <- getwd()
        filenum.inc <- 1
        output.file <- paste(current.folder, '/Aoristic_summary_', filenum.inc, '.xlsx',sep='')
        # If user already has a _X file, increment until we have a free _X filename available
        while (file.exists(output.file)) {
          filenum.inc <- filenum.inc + 1
          output.file <- paste(current.folder, '/Aoristic_summary_', filenum.inc, '.xlsx',sep='')
        }

        openxlsx::write.xlsx(df4, output.file, sheetName = "Aoristic",
                   colnames = TRUE, rownames = TRUE, append = FALSE)

        txt1 <- paste('\n****** Aoristic summary file for Excel written to: \n',output.file, sep='       ')
        message(txt1)
    }

    
    
    # JPG OUTPUT: Switch output='jpg' ---------------------------------
    if (output == "jpg"){
      
      current.folder <- getwd()
      filenum.inc <- 1
      output.file <- paste(current.folder, '/Aoristic_summary_', filenum.inc, '.jpg',sep='')
      # If user already has a _X file, increment until we have a free _X filename available
      while (file.exists(output.file)) {
        filenum.inc <- filenum.inc + 1
        output.file <- paste(current.folder, '/Aoristic_summary_', filenum.inc, '.jpg',sep='')
      }
      
      days=c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
    
      jpeg(output.file, width = 1200, height = 400)
      
      df5 <- df4 %>%
        select(-c(Range)) %>%
        tidyr::gather (df4, f) %>%
        mutate (the.hour = rep(0:23, 7)) %>%
        mutate (the.day = rep(days, times = c(24, 24, 24, 24, 24, 24, 24))) %>%
        mutate (rat.hour = (seq(1, 168, by = 1))) %>%
        mutate (f = as.numeric(f))
      
      # calculate the midpoint
      a.min <- min(df5$f)
      a.max <- max(df5$f)
      a.med <- ((a.max-a.min)/2)+a.min

    p <- ggplot(data = df5, aes(x = the.hour, y = reorder(the.day, -(rat.hour)))) +
        geom_tile(aes(fill = f), color = "white") +
        geom_text(aes(label = round(f))) +
        scale_x_continuous(breaks = seq(0,23,1)) +
        scale_fill_gradient2(low = muted("lightblue"), mid = "gray80",
                             high = scales::muted("red"), midpoint = a.med,
                             breaks = scales::pretty_breaks(n = 6)) +
                            labs(fill = "Frequency", x = "Hour", y = "")

    p <- p +  theme(legend.title = element_text( size = 22),
              legend.key.height = unit(1, "cm"),
              legend.text = element_text(size = 18),
              axis.title.x = element_text(size = 18),
              axis.title.y = element_text(size = 18),
              axis.text = element_text(size = 18),
              panel.grid.major = element_blank(),
              panel.grid.minor = element_blank(),
              panel.background = element_rect(fill = 'white'),
              panel.border = element_blank())
      p <- p + ggtitle(" ")
      p <- p + theme(plot.title = element_text(size = 22))

      print(p)
      dev.off()
      
      while (!is.null(dev.list()))  dev.off()
      
      txt1 <- paste('\n****** Aoristic summary grid jpg written to: \n', output.file, sep='       ')
      message(txt1)
            
      }

  return(df4)
}
