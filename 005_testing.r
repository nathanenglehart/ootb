library(readODS)
library(ggplot2)
library(broom)
library(MASS)
library(margins)
library(AER)
library(stringr)

olive_green <- "#808000"
dark_blue <- "#00008B"
teal <- "#008080"
dark_green <- "#006400"
gray <- "#4B4B4B"
sky_blue <- "#87CEEB"
washu_red <- "#A51417"

verbose = TRUE
count = FALSE
ratio = TRUE

nra_2020_fpath = "money/2020-NRA-donations_e68468b7-28be-4b72-ba23-140b9d038c23.csv"
nra_2022_fpath = "money/2022-NRA-donations_5b11c84d-6d8d-4908-97a0-b09e35ec34ff.csv"
voteview_members_fpath = "voteview/Hall_members.csv"

df_nra <- read.csv(nra_2020_fpath)
df_voteview_members <- read.csv(voteview_members_fpath)

df_nra <- df_nra[df_nra$Chamber == "House",]
df_nra <- df_nra[df_nra$View == "Republican",]
df_nra$state <- substr(df_nra$Recipient.Type, 14, 15)
df_nra$district <- substr(df_nra$Recipient.Type, 16, 17)
df_nra$district <- sub("^0+", "", df_nra$district)
df_nra$rep <- df_nra$rep <- stringr::str_split_fixed(df_nra$Recipient, " ", 2)[,1]
df_nra$uniqueid <- ifelse(df_nra$district != "", 
			  paste0(df_nra$rep, " ", df_nra$state, "-", df_nra$district),
			  paste0(df_nra$rep, " ", df_nra$state))
df_nra$easyid <- paste0(df_nra$rep, " ", df_nra$state)

df_voteview_members <- df_voteview_members[df_voteview_members$congress == 118,] 
df_voteview_members <- df_voteview_members[df_voteview_members$party_code == 200,]
df_voteview_members$state <- df_voteview_members$state_abbrev
df_voteview_members$district <- df_voteview_members$district_code
df_voteview_members$rep <- stringr::str_split_fixed(df_voteview_members$bioname, ",", 2)[, 1]
df_voteview_members$rep <- stringr::str_to_title(stringr::str_to_lower(df_voteview_members$rep))

df_voteview_members$rep[df_voteview_members$rep == "D'esposito"] <- "D’Esposito"
df_voteview_members$rep[df_voteview_members$rep == "Desjarlais"] <- "DesJarlais"
df_voteview_members$rep[df_voteview_members$rep == "Lamalfa"] <- "LaMalfa"
df_voteview_members$rep[df_voteview_members$rep == "Laturner"] <- "LaTurner"
df_voteview_members$rep[df_voteview_members$rep == "Lalota"] <- "LaLota"
df_voteview_members$rep[df_voteview_members$rep == "Mccaul"] <- "McCaul"
df_voteview_members$rep[df_voteview_members$rep == "Mchenry"] <- "McHenry"
df_voteview_members$rep[df_voteview_members$rep == "Mcmorris Rodgers"] <- "McMorris Rodgers"
df_voteview_members$rep[df_voteview_members$rep == "Lahood"] <- "LaHood"
df_voteview_members$rep[df_voteview_members$rep == "Mccarthy"] <- "McCarthy"
df_voteview_members$rep[df_voteview_members$rep == "Mcclain"] <- "McClain"
df_voteview_members$rep[df_voteview_members$rep == "Mcclintock"] <- "McClintock"
df_voteview_members$rep[df_voteview_members$rep == "Mccormick"] <- "McCormick"

df_voteview_members$district[df_voteview_members$rep == "Armstrong"] <- ""
df_voteview_members$district[df_voteview_members$rep == "Johnson" & df_voteview_members$state == "SD"] <- ""

df_voteview_members$uniqueid <- ifelse(df_voteview_members$district != "", 
				       paste0(df_voteview_members$rep, " ", df_voteview_members$state, "-", df_voteview_members$district),
				       paste0(df_voteview_members$rep, " ", df_voteview_members$state))

df_1 <- read.csv("df_yolow_clean_1.csv")
df_2 <- read.csv("df_yolow_clean_rep.csv")
df_3 <- read_ods("representatives_118_data.ods")

df_1 <- df_1[df_1$party == "R",]
df_2 <- df_2[df_2$party == "R",]

df_2$gun <- as.numeric(df_2$gun)
df_2$gun_strict <- as.numeric(df_2$gun_strict)

get_summary_stats <- function(df_1, df_2) {
	
	# df_1 should be df_1
	# df_2 can be df_x for any x > 1

	print(paste0("# gun posts: ",sum(df_2$gun_post)))
	print(paste0("# total posts: ",sum(df_2$num_posts)))
	print(paste0("# distinct accts: ",length(unique(df_1$acct))))
	print(paste0("# women reps: ", sum(df_2$woman == 1)))
	print(paste0("# men reps: ", sum(df_2$woman == 0)))
	print(paste0("# reps: ", length(df_2$woman)))
	print(paste0("% women reps: ", sum(df_2$woman) / length(df_2$woman)))
	print(paste0("% gun posts by women: ", sum(df_2[df_2$woman == 1,]$gun_post) / sum(df_2$gun_post)))
	print(paste0("mean guns posted:", mean(df_2$gun_post)))
	print(paste0("median guns posted:", median(df_2$gun_post)))
	print(paste0("# woman above mean:", sum(df_2[df_2$gun_post > mean(df_2$gun_post),]$woman)))
	print(paste0("# woman above median:", sum(df_2[df_2$gun_post > median(df_2$gun_post),]$woman)))
	print(paste0("min log(num_posts):", min(log(df_2$num_posts))))
	print(paste0("max log(num_posts):", max(log(df_2$num_posts))))
}

df_5 <- merge(df_2,
	      df_3, 
	      by = "uniqueid",
	      all.x = T)

df_5 <- merge(df_5,
	      df_nra, 
	      by = c("uniqueid"),
	      all.x = T)

df_5 <- merge(df_5,
	      df_voteview_members,
	      by = c("uniqueid"),
	      all.x = T)

df_5$woman <- df_5$woman.y

df_5$born[df_5$uniqueid == "Fong CA-20"] <- 1979 # https://en.wikipedia.org/wiki/Vince_Fong
df_5$born[df_5$uniqueid == "Lopez CO-4"] <- 1964 # https://en.wikipedia.org/wiki/Greg_Lopez
df_5$born[df_5$uniqueid == "Rulli OH-6"] <- 1969 # https://en.wikipedia.org/wiki/Michael_Rulli

df_5$age <- 2024 - df_5$born

df_5$DW_NOMINATE <- df_5$nominate_dim1
df_5$nra_donations <- as.numeric(gsub("[$,]", "", df_5$Total))
df_5$nra_donations <- ifelse(is.na(df_5$nra_donations), 0, df_5$nra_donations)
df_5$nra_donations <- ifelse(df_5$nra_donations < 0, 0, df_5$nra_donations)

#
# https://en.wikipedia.org/wiki/118th_United_States_Congress#Leadership
# 
# Presiding
#
#     Speaker:
#         Kevin McCarthy (R), January 7, 2023 – October 3, 2023
#         Patrick McHenry (R), October 3–25, 2023 (as Speaker pro tempore)
#         Mike Johnson (R), from October 25, 2023
#
# Majority (Republican)
#
#     Majority Leader: Steve Scalise (LA 1)
#     Majority Whip: Tom Emmer (MN 6)
#     Conference Chair: Elise Stefanik (NY 21)
#     Vice Chair of the House Republican Conference:
#         Mike Johnson (LA 4), until October 25, 2023
#         Blake Moore (UT 1), since November 8, 2023
#     Policy Committee Chairman: Gary Palmer (AL 6)
#     Conference Secretary: Lisa McClain (MI 9)
#     Campaign Committee Chairman: Richard Hudson (NC 9)
#     Majority Chief Deputy Whip: Guy Reschenthaler (PA 14)
#

df_5$leadership <- 0
df_5$leadership[df_5$uniqueid == "Johnson LA-4"] <- 1 
df_5$leadership[df_5$uniqueid == "McCarthy CA-20"] <- 1 
df_5$leadership[df_5$uniqueid == "McHenry NC-10"] <- 1 
df_5$leadership[df_5$uniqueid == "Scalise LA-1"] <- 1 
df_5$leadership[df_5$uniqueid == "Emmer MN-6"] <- 1
df_5$leadership[df_5$uniqueid == "Stefanik NY-21"] <- 1
df_5$leadership[df_5$uniqueid == "Moore UT-1"] <- 1
df_5$leadership[df_5$uniqueid == "Palmer AL-6"] <- 1
df_5$leadership[df_5$uniqueid == "McClain MI-9"] <- 1
df_5$leadership[df_5$uniqueid == "Hudson NC-9"] <- 1
df_5$leadership[df_5$uniqueid == "Reschenthaler PA-14"] <- 1

df_6 <- df_5
df_6 <- df_6[df_6$uniqueid != "Boebert CO-3",] 

if(verbose) {
	get_summary_stats(df_1, df_5)
}

### test relationship between gun post intensity and being a woman rep ###

df_5$ratio <- df_5$gun_post / log(df_5$num_posts)
model <- lm(ratio ~ woman + DW_NOMINATE + age + nra_donations, data = df_5)
print(max(df_5$ratio))
print(min(df_5$ratio))
print(summary(model))
print(nobs(model))
used_rows <- model$model
deleted_rows <- df_5[!rownames(df_5) %in% rownames(used_rows), ]
print(deleted_rows)

df_5$gun_post_ratio <- df_5$gun_post / log(df_5$num_posts)
df_6$gun_post_ratio <- df_6$gun_post / log(df_6$num_posts)
df_5$gun_strict_post_ratio <- df_5$gun_strict_post / log(df_5$num_posts)
df_6$gun_strict_post_ratio <- df_6$gun_strict_post / log(df_6$num_posts)
	

get_effect_of_woman_on_gun_ratio <- function(outcome, controls_0, controls_1, controls_2, controls_3) {

	formula <- as.formula(paste(outcome, "~", controls_0))
	model_0_ols <- lm(formula, data = df_5)
	model_0_ols_me <- summary(margins(model_0_ols))

	if(verbose) {
		print("Running model_0")
	}

	formula <- as.formula(paste(outcome, "~", controls_1))
	model_1_ols <- lm(formula, data = df_5)
	model_1_ols_me <- summary(margins(model_1_ols))

	if(verbose) {
		print("Running model_1")
	}

	formula <- as.formula(paste(outcome, "~", controls_2))
	model_2_ols <- lm(formula, data = df_5)
	model_2_ols_me <- summary(margins(model_2_ols))

	if(verbose) {
		print("Running model_2")
	}

	formula <- as.formula(paste(outcome, "~", controls_3))
	model_3_ols <- lm(formula, data = df_6)
	model_3_ols_me <- summary(margins(model_3_ols))

	if(verbose) {
		print("Running model_3")
	}

	return(list(model_0_ols = model_0_ols, 
		    model_1_ols = model_1_ols, 
		    model_2_ols = model_2_ols, 
		    model_3_ols = model_3_ols,
		    model_0_ols_me = model_0_ols_me, 
		    model_1_ols_me = model_1_ols_me, 
		    model_2_ols_me = model_2_ols_me, 
		    model_3_ols_me = model_3_ols_me))
}


controls_0 = "woman"
controls_1 = "woman + nra_donations"
controls_2 = "woman + nra_donations + DW_NOMINATE + age"
controls_3 = "woman + nra_donations + DW_NOMINATE + age"

models <- list(gun_strict = get_effect_of_woman_on_gun_ratio("gun_strict_post_ratio", # gun_strict_post
				       controls_0, 
				       controls_1, 
				       controls_2, 
				       controls_3), 
	       gun = get_effect_of_woman_on_gun_ratio("gun_post_ratio", # gun_post
				       controls_0, 
				       controls_1, 
				       controls_2, 
				       controls_3))

model_type_name <- "_ols_me"
y_axis_label <- "effect of woman on gun posting intensity (# posts containing firearms / log(total posts))"

library(ggplot2)
library(dplyr)

marginal_effects_data <- list()

for (i in 1:2) {
  model_group <- models[[i]]

  for (j in 0:3) {
    me_name <- paste0("model_", j, model_type_name)
    marginal_effect_df <- model_group[[me_name]]

    marginal_effect_df <- subset(marginal_effect_df, factor == "woman")
    print(marginal_effect_df)

    marginal_effect_df <- marginal_effect_df %>%
      mutate(
	model = paste0(j),
        group = ifelse(i == 1, "strict", "non-strict"),
        variable = as.character(factor)
      )
    
    marginal_effects_data[[paste0("Group_", i, "_Model_", j)]] <- marginal_effect_df
  }
}

combined_data <- bind_rows(marginal_effects_data)
print(head(combined_data))
q(save = "no")

ggplot(combined_data, aes(x = paste(variable, model, sep = "_"), y = AME)) +
  geom_point(color = washu_red, size = 3) +
  geom_errorbar(
    aes(ymin = lower, ymax = upper),
    width = 0.2,
    color = washu_red 
  ) +
  coord_flip() + 
  scale_x_discrete(
    labels = c(
      "woman_0" = "no controls",
      "woman_1" = "nra \n donations",
      "woman_2" = "all controls",
      "woman_3" = "all controls \n no rep Boebert"
    )
  ) +
  facet_wrap(~ group, scales = "free_x") +  # free y-axis scaling per facet
  theme_minimal() +
  labs(
    x = "model specification",
    y = y_axis_label 
  ) +
  theme(
    legend.position = "none", 
    panel.spacing = unit(2, "lines"), 
    panel.border = element_rect(color = "black", fill = NA, linewidth = 1), # black border around each panel
    axis.text.y = element_text(size = 10, hjust = 1) 
  ) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black") # add a reference line at 0

ggsave("fig3_new.png", plot = last_plot(), width = 12, height = 6)

### check the disproprotionate attention hypothesis! ###

df_google_analytics <- read.csv("google_analytics.csv")

df_5 <- merge(df_5,
	      df_google_analytics,
	      by = c("uniqueid"), 
	      all.x = TRUE)

df_5$average[is.na(df_5$average)] <- 0 # if not searchable on google analytics, that means nearly 0 searches compared to other reps

disprop_attn <- function(gun_var) {

	df_5$gun_post_ratio <- df_5$gun_post / log(df_5$num_posts)
	df_6$gun_post_ratio <- df_6$gun_post / log(df_6$num_posts)
	
	if(gun_var == "strict") {
		df_5$gun_post_ratio <- df_5$gun_strict_post / log(df_5$num_posts)
		df_6$gun_post_ratio <- df_6$gun_strict_post / log(df_6$num_posts)
	}

	model <- lm(average ~ woman * gun_post_ratio + age + DW_NOMINATE, data = df_5)
	print(summary(model))
	print(nobs(model))

	colnames(df_5) <- make.unique(colnames(df_5))
	gun_post_vals <- seq(min(df_5$gun_post_ratio) - 2, max(df_5$gun_post_ratio) + 5, length.out = 100)

	predict_data <- expand.grid(
	  gun_post_ratio = gun_post_vals,
	  woman = c(0, 1),
	  age = mean(df_5$age, na.rm = TRUE),
	  DW_NOMINATE = mean(df_5$DW_NOMINATE, na.rm = TRUE)
	)

	predictions <- predict(model, newdata = predict_data, interval = "confidence")
	predict_data$average <- predictions[, "fit"]
	predict_data$upper <- predictions[, "upr"]
	predict_data$lower <- predictions[, "lwr"]

	ggplot() +
	  geom_line(
	    data = predict_data, 
	    aes(x = gun_post_ratio, y = average, color = factor(woman)), 
	    size = 1.2
	  ) +
	  geom_ribbon(
	    data = predict_data,
	    aes(
	      x = gun_post_ratio,
	      ymin = lower,
	      ymax = upper,
	      fill = factor(woman)
	    ),
	    alpha = 0.2
	  ) +
	  geom_point(
	    data = df_5, 
	    aes(x = gun_post_ratio, y = average, color = factor(woman)), 
	    size = 2, alpha = 0.7
	  ) +
	  geom_label(
	  data = df_5[df_5$uniqueid == "Boebert CO-3" | df_5$uniqueid == "Mace SC-1" | df_5$uniqueid == "Crenshaw TX-2" | df_5$uniqueid == "Johnson LA-4" | df_5$uniqueid == "Yakym IN-2" | df_5$uniqueid == "Harshbarger TN-1" | df_5$uniqueid == "Kelly PA-16" | df_5$uniqueid == "Greene GA-14" | df_5$uniqueid == "Donalds FL-19" | df_5$uniqueid == "Stefanik NY-21" | df_5$uniqueid == "Crane AZ-2" | df_5$uniqueid == "De La Cruz TX-15" | df_5$uniqueid == "Luna FL-13",],
	  aes(x = gun_post_ratio, y = average, label = uniqueid),
	  hjust = 0, vjust = 1, size = 3, alpha = 0.5
	) + 
	  labs(
	#    title = "Effect of ln_gun_post on ln_followers by Gender",
	    x = paste0("gun post intensity", " (", gun_var, ")"),
	    y = "normalized google searches during 118th congress",
	    color = "Gender",
	    fill = "Gender"
	  ) +
	  scale_color_manual(
	    values = c("0" = gray, "1" = washu_red),
	    labels = c("Men", "Women")
	  ) +
	  scale_fill_manual(
	    values = c("0" = gray, "1" = washu_red),
	    labels = c("Men", "Women")
	  ) +
	  theme_minimal()

	if(gun_var == "strict") {
		ggsave("fig4-strict.png", width = 10, height = 6, dpi = 300)
	} else {	
		ggsave("fig4-nonstrict.png", width = 10, height = 6, dpi = 300)
	}
}
disprop_attn(gun_var = "strict")
disprop_attn(gun_var = "non-strict")

### word2vec ###
