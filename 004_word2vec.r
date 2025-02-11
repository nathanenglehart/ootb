library(tidyverse)
library(broom)
library(kableExtra)
library(xtable)
library(dplyr)
library(ggplot2)
library(gridExtra)

olive_green = "#808000"
dark_blue = "#00008B"
teal = "#008080"
dark_green = "#006400"
gray = "#4B4B4B"
sky_blue = "#87CEEB"
washu_red = "#A51417"

df <- read.csv("word2vec_with_similarity.csv")

print(head(df[,c('post_id','gun_post','similarity_to_aggressiveness')]))
print(max(df$similarity_to_aggressiveness))
print(min(df$similarity_to_aggressiveness))

df$gun_post <- ifelse(df$gun_post == 1, "gun", "no_gun")
df$gun_strict_post <- ifelse(df$gun_strict_post == 1, "gun", "no_gun")
#print(df$woman)
#prin
#print(head(df$similarity_to_aggressiveness))
#print(t.test(similarity_to_aggressiveness ~ gun_strict_post, data = df))
#q(save = "no")

get_t_test_plot <- function(df, y_lab) {
	extract_ci <- function(test_result) {
	  return(c(test_result$conf.int[1], test_result$conf.int[2]))
	}

	print(head(df$gun_strict_post))
	t_tests <- list(
	  "Aggressiveness (Gun Strict Post)" = t.test(similarity_to_aggressiveness ~ gun_strict_post, data = df),
	  "Competitiveness (Gun Strict Post)" = t.test(similarity_to_competitiveness ~ gun_strict_post, data = df),
	  "Strength (Gun Strict Post)" = t.test(similarity_to_strength ~ gun_strict_post, data = df),
	  "Conservatism (Gun Strict Post)" = t.test(similarity_to_conservatism ~ gun_strict_post, data = df),
	  "Second Amendment (Gun Strict Post)" = t.test(similarity_to_2a ~ gun_strict_post, data = df),
	  "Aggressiveness (Gun Post)" = t.test(similarity_to_aggressiveness ~ gun_post, data = df),
	  "Competitiveness (Gun Post)" = t.test(similarity_to_competitiveness ~ gun_post, data = df),
	  "Strength (Gun Post)" = t.test(similarity_to_strength ~ gun_post, data = df),
	  "Conservatism (Gun Post)" = t.test(similarity_to_conservatism ~ gun_post, data = df),
	  "Second Amendment (Gun Post)" = t.test(similarity_to_2a ~ gun_post, data = df)
	)

	

	results <- data.frame(
	  Variable = names(t_tests),
	  t(sapply(t_tests, extract_ci))
	)

	colnames(results) <- c("Variable", "Lower_CI", "Upper_CI")

	if(y_lab == "effect size (women)") {

		results <- results %>%
		  mutate(
		    Measurement = ifelse(grepl("Strict", Variable), "Strict", "Non-Strict"),
		    Variable = gsub(" \\(Gun (Strict )?Post\\)", "", Variable),  # Clean y-axis labels
		    group = "women"
		  )

#		pd <- position_dodge(width = 0.5)

#		women_plot <- ggplot(results, aes(x = Variable, y = (Lower_CI + Upper_CI) / 2, color = Measurement)) +
#		  geom_point(aes(shape = Measurement), size = 4, position = pd) +  # Adjust shape and position
#		  geom_errorbar(aes(ymin = Lower_CI, ymax = Upper_CI), width = 0.2, position = pd) +  # Error bars
#		  geom_hline(yintercept = 0, linetype = "dashed", color = "black") +  # Reference line at zero
#		  scale_color_manual(name = "Measurement", values = c("Strict" = "coral", "Non-Strict" = "steelblue")) +  # Colors
#		  scale_shape_manual(name = "Measurement", values = c("Strict" = 17, "Non-Strict" = 19)) +  # Triangle and circle
#		  coord_flip() +  # Flip for better readability
#		  theme_bw() +  # Consistent theme
#		  labs(y = y_lab, x = "Dictionaries") +  # Labels
#		  theme(axis.text = element_text(size = 12), axis.title = element_text(size = 14))

		#women_plot <- ggplot(results, aes(x = Variable, y = (Lower_CI + Upper_CI) / 2)) +
		#  geom_point(size = 3, color = sky_blue) +
		#  geom_errorbar(aes(ymin = Lower_CI, ymax = Upper_CI), width = 0.2, color = sky_blue) +
		#      geom_hline(yintercept = 0, linetype = "dashed", color = "black") +  # Dashed horizontal line at zero
		#  theme_minimal() +
		#  coord_flip() + # Flip for better readability
		#  labs(y = y_lab) + 
		#  theme(axis.text = element_text(size = 12), axis.title = element_text(size = 14))
		#return(women_plot)
		return(results)
	} 

	# Create a new column to distinguish Strict vs. Non-Strict
	results <- results %>%
	  mutate(
	    Measurement = ifelse(grepl("Strict", Variable), "Strict", "Non-Strict"),
	    Variable = gsub(" \\(Gun (Strict )?Post\\)", "", Variable),  # Clean y-axis labels
	    group = "men"
	  )

	return(results)

	# Set position dodge width for separation
#	pd <- position_dodge(width = 0.5)

	# Create the plot
#	men_plot <- ggplot(results, aes(x = Variable, y = (Lower_CI + Upper_CI) / 2, color = Measurement)) +
#	  geom_point(aes(shape = Measurement), size = 4, position = pd) +  # Adjust shape and position
#	  geom_errorbar(aes(ymin = Lower_CI, ymax = Upper_CI), width = 0.2, position = pd) +  # Error bars
#	  geom_hline(yintercept = 0, linetype = "dashed", color = "black") +  # Reference line at zero
#	  scale_color_manual(name = "Measurement", values = c("Strict" = "coral", "Non-Strict" = "steelblue")) +  # Colors
#	  scale_shape_manual(name = "Measurement", values = c("Strict" = 17, "Non-Strict" = 19)) +  # Triangle and circle
#	  coord_flip() +  # Flip for better readability
#	  theme_bw() +  # Consistent theme
#	  labs(y = y_lab, x = "Dictionaries") +  # Labels
#	  theme(axis.text = element_text(size = 12), axis.title = element_text(size = 14))

#	return(men_plot)


		#men_plot <- ggplot(results, aes(x = Variable, y = (Lower_CI + Upper_CI) / 2)) +
		#  geom_point(size = 3, color = sky_blue) +
		#  geom_errorbar(aes(ymin = Lower_CI, ymax = Upper_CI), width = 0.2, color = sky_blue) +
		#  geom_hline(yintercept = 0, linetype = "dashed", color = "black") + 
		#  theme_minimal() +
		#  coord_flip() + 
		#  labs(y = y_lab) + 
		#  theme(axis.text = element_text(size = 12), axis.title = element_text(size = 14)) 
#		return(men_plot)
}
#get_t_test_plot(df[df$woman == 1,], y_lab = "effect size (women)")
#get_t_test_plot(df[df$woman == 0,], y_lab = "effect size (men)")

df_man <- df[df$woman == 0,]
df_woman <- df[df$woman == 1,]
print(head(df_woman$gun_strict_post))
print(head(df_man$gun_strict_post))
# Store the plots as objects
res_women <- get_t_test_plot(df_woman, y_lab = "effect size (women)")
#ggsave("word2vec_women.png", width = 8, height = 6, dpi = 300)
res_men <- get_t_test_plot(df_man, y_lab = "effect size (men)")
#ggsave("word2vec_men.png", width = 8, height = 6, dpi = 300)

combined_data <- bind_rows(res_women, res_men)
print(as.data.frame(combined_data))

combined_data <- combined_data %>%
  mutate(Variable = factor(Variable, levels = unique(Variable)))

ggplot(combined_data, aes(x = group, y = (Lower_CI + Upper_CI) / 2, color = Measurement)) +
  geom_point(aes(shape = Measurement), size = 4, position = position_dodge(width = 0.5)) +  # Use dodge to separate points
  geom_errorbar(aes(ymin = Lower_CI, ymax = Upper_CI), width = 0.2, position = position_dodge(width = 0.5)) + 
  geom_hline(yintercept = 0, linetype = "dashed", color = "black") +  # Reference line at 0
  scale_color_manual(values = c("Strict" = "coral", "Non-Strict" = "steelblue")) +  # Custom colors
  scale_shape_manual(values = c("Strict" = 17, "Non-Strict" = 19)) +  # Triangle for Strict, Circle for Non-Strict
  facet_wrap(~ group, scales = "free_x", strip.position = "top") +  # Create side-by-side panels for men and women
  coord_flip() +  # Flip coordinates for better readability
  theme_minimal() +
  labs(
    y = "Variable",
    x = NULL,
    color = "Measurement",
    shape = "Measurement"
  ) +
  theme(
    legend.position = "top",
    panel.spacing = unit(1, "lines"),
    strip.background = element_blank(),
    strip.text.x = element_text(size = 12, face = "bold"),
    axis.text.y = element_text(size = 10),
    axis.title.y = element_text(size = 12),
    axis.title.x = element_blank(),  # Remove x-axis label
    panel.border = element_rect(color = "black", fill = NA, size = 0.5)
  )



#library(ggpubr)
#ggarrange(plot_women, plot_men, ncol = 2, widths = c(4,4,4))
#ggsave("word2vec.png", width = 14, height = 6, dpi = 300)


