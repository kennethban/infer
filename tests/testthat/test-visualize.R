context("visualize")

library(dplyr)
library(vdiffr)

set.seed(42)

Sepal.Width_resamp <- iris %>%
  specify(Sepal.Width ~ NULL) %>%
  hypothesize(null = "point", med = 3) %>%
  generate(reps = 10, type = "bootstrap") %>%
  calculate(stat = "median")

obs_slope <- lm(Sepal.Length ~ Sepal.Width, data = iris_tbl) %>%
  broom::tidy() %>%
  dplyr::filter(term == "Sepal.Width") %>%
  dplyr::select(estimate) %>%
  dplyr::pull()

obs_diff <- iris_tbl %>%
  group_by(Sepal.Length.Group) %>%
  summarize(prop = mean(Sepal.Width.Group == ">5")) %>%
  summarize(diff(prop)) %>%
  pull()

obs_z <- sqrt(
  stats::prop.test(
    x = table(iris_tbl$Sepal.Length.Group, iris_tbl$Sepal.Width.Group),
    n = nrow(iris_tbl),
    alternative = "two.sided",
    correct = FALSE
  )$statistic
)

obs_diff_mean <- iris_tbl %>%
  group_by(Sepal.Length.Group) %>%
  summarize(mean_sepal_width = mean(Sepal.Width)) %>%
  summarize(diff(mean_sepal_width)) %>%
  pull()

obs_t <- iris_tbl %>%
  t_stat(Sepal.Width ~ Sepal.Length.Group, order = c(">5", "<=5"))

obs_F <- anova(
    aov(formula = Sepal.Width ~ Species, data = iris_tbl)
  )$`F value`[1]

test_that("visualize basic tests", {
  expect_doppelganger("visualize", visualize(Sepal.Width_resamp))
  
  # visualise also works
  expect_doppelganger("visualise", visualise(Sepal.Width_resamp))
  
  expect_error(Sepal.Width_resamp %>% visualize(bins = "yep"))
  expect_doppelganger(
    "vis-sim-right-1",
    expect_warning(
      iris_tbl %>%
        specify(Sepal.Length ~ Sepal.Width) %>%
        hypothesize(null = "independence") %>%
        generate(reps = 100, type = "permute") %>%
        calculate(stat = "slope") %>%
        visualize(obs_stat = obs_slope, direction = "right"),
      "deprecated"
    )
  )

  # obs_stat not specified
  expect_error(
    iris_tbl %>%
      specify(Sepal.Width.Group ~ Sepal.Length.Group, success = "large") %>%
      hypothesize(null = "independence") %>%
      generate(reps = 100, type = "permute") %>%
      calculate(stat = "diff in props", order = c(">5", "<=5")) %>%
      visualize(direction = "both")
  )

  expect_doppelganger(
    "vis-sim-both-1",
    expect_warning(
      iris_tbl %>%
        specify(Sepal.Width.Group ~ Sepal.Length.Group, success = "large") %>%
        hypothesize(null = "independence") %>%
        generate(reps = 100, type = "permute") %>%
        calculate(stat = "diff in props", order = c(">5", "<=5")) %>%
        visualize(direction = "both", obs_stat = obs_diff),
      "deprecated"
    )
  )

  expect_doppelganger(
    "vis-theor-none-1",
    expect_warning(
      iris_tbl %>%
        specify(Sepal.Width.Group ~ Sepal.Length.Group, success = "large") %>%
        hypothesize(null = "independence") %>%
        calculate(stat = "z", order = c(">5", "<=5")) %>%
        visualize(method = "theoretical")
    )
  )

  # diff in props and z on different scales
  expect_error(
    expect_warning(
      iris_tbl %>%
        specify(Sepal.Width.Group ~ Sepal.Length.Group, success = "large") %>%
        hypothesize(null = "independence") %>%
        generate(reps = 100, type = "permute") %>%
        calculate(stat = "diff in props", order = c(">5", "<=5")) %>%
        visualize(method = "both", direction = "both", obs_stat = obs_diff)
    )
  )

  expect_doppelganger(
    "vis-sim-none-1",
    expect_silent(
      iris_tbl %>%
        specify(Sepal.Width.Group ~ Sepal.Length.Group, success = "large") %>%
        hypothesize(null = "independence") %>%
        generate(reps = 100, type = "permute") %>%
        calculate(stat = "diff in props", order = c(">5", "<=5")) %>%
        visualize()
    )
  )

  expect_doppelganger(
    "vis-both-both-1",
    expect_warning(
      iris_tbl %>%
        specify(Sepal.Width.Group ~ Sepal.Length.Group, success = "large") %>%
        hypothesize(null = "independence") %>%
        generate(reps = 100, type = "permute") %>%
        calculate(stat = "z", order = c(">5", "<=5")) %>%
        visualize(method = "both", direction = "both", obs_stat = obs_z)
    )
  )

  expect_doppelganger(
    "vis-both-both-2",
    expect_warning(
      iris_tbl %>%
        specify(Sepal.Width.Group ~ Sepal.Length.Group, success = "large") %>%
        hypothesize(null = "independence") %>%
        generate(reps = 100, type = "permute") %>%
        calculate(stat = "z", order = c("<=5", ">5")) %>%
        visualize(method = "both", direction = "both", obs_stat = -obs_z)
    )
  )

  expect_doppelganger(
    "vis-both-left-1",
    expect_warning(
      iris_tbl %>%
        specify(Sepal.Length ~ Sepal.Width.Group) %>%
        hypothesize(null = "independence") %>%
        generate(reps = 100, type = "permute") %>%
        calculate(stat = "t", order = c("small", "large")) %>%
        visualize(method = "both", direction = "left", obs_stat = obs_t)
    )
  )

  expect_doppelganger(
    "vis-theor-left-1",
    expect_warning(
      iris_tbl %>%
        specify(Sepal.Length ~ Sepal.Width.Group) %>%
        hypothesize(null = "independence") %>%
#         generate(reps = 100, type = "permute") %>%
        calculate(stat = "t", order = c("small", "large")) %>%
        visualize(method = "theoretical", direction = "left", obs_stat = obs_t)
    )
  )
  
  expect_doppelganger(
    "vis-both-none-1",
    expect_warning(
      iris_tbl %>%
        specify(Petal.Width ~ NULL) %>%
        hypothesize(null = "point", mu = 1) %>%
        generate(reps = 100) %>%
        calculate(stat = "t") %>%
        visualize(method = "both")
    )
  )

  expect_doppelganger(
    "vis-theor-none-2",
    expect_warning(
      iris_tbl %>%
        specify(Sepal.Length ~ Sepal.Length.Group) %>%
        hypothesize(null = "independence") %>%
        visualize(method = "theoretical")
    )
  )

  expect_doppelganger(
    "vis-theor-none-3",
    expect_warning(
      iris_tbl %>%
        specify(Sepal.Length ~ Species) %>%
        hypothesize(null = "independence") %>%
        visualize(method = "theoretical")
    )
  )

  expect_doppelganger(
    "vis-both-right-1",
    expect_warning(
      iris_tbl %>%
        specify(Sepal.Length ~ Species) %>%
        hypothesize(null = "independence") %>%
        generate(reps = 100, type = "permute") %>%
        calculate(stat = "F") %>%
        visualize(method = "both", obs_stat = obs_F, direction = "right")
    )
  )

  expect_doppelganger(
    "vis-both-left-2",
    expect_warning(
      iris_tbl %>%
        specify(Sepal.Length ~ Species) %>%
        hypothesize(null = "independence") %>%
        generate(reps = 100, type = "permute") %>%
        calculate(stat = "F") %>%
        visualize(method = "both", obs_stat = obs_F, direction = "left")
    )
  )

  expect_doppelganger(
    "vis-both-right-2",
    expect_warning(
      iris_tbl %>%
        specify(Sepal.Width.Group ~ Species, success = "large") %>%
        hypothesize(null = "independence") %>%
        generate(reps = 100, type = "permute") %>%
        calculate(stat = "Chisq") %>%
        visualize(method = "both", obs_stat = obs_F, direction = "right")
    )
  )

  expect_doppelganger(
    "vis-theor-right-1",
    expect_warning(
      iris_tbl %>%
        specify(Sepal.Width.Group ~ Species, success = "large") %>%
        hypothesize(null = "independence") %>%
#         calculate(stat = "Chisq") %>%
        visualize(method = "theoretical", obs_stat = obs_F, direction = "right")
    )
  )

  expect_doppelganger(
    "vis-both-none-2",
    expect_warning(
      iris_tbl %>%
        specify(Species ~ NULL) %>%
        hypothesize(
          null = "point",
          p = c("setosa" = 0.4, "versicolor" = 0.4, "virginica" = 0.2)
        ) %>%
        generate(reps = 100, type = "simulate") %>%
        calculate(stat = "Chisq") %>%
        visualize(method = "both")
    )
  )

  # traditional instead of theoretical
  expect_error(
    iris_tbl %>%
      specify(Species ~ NULL) %>%
      hypothesize(
        null = "point",
        p = c("setosa" = 0.4, "versicolor" = 0.4, "virginica" = 0.2)
      ) %>%
#       generate(reps = 100, type = "simulate") %>%
#       calculate(stat = "Chisq") %>%
      visualize(method = "traditional")
  )

  expect_doppelganger(
    "vis-theor-none-4",
    expect_warning(
      iris_tbl %>%
        specify(Species ~ NULL) %>%
        hypothesize(
          null = "point",
          p = c("setosa" = 0.4, "versicolor" = 0.4, "virginica" = 0.2)
        ) %>%
#         generate(reps = 100, type = "simulate") %>%
#         calculate(stat = "Chisq") %>%
        visualize(method = "theoretical")
    )
  )

  expect_doppelganger(
    "vis-sim-both-2",
    expect_warning(
      iris_tbl %>%
        specify(Petal.Width ~ Sepal.Width.Group) %>%
        hypothesize(null = "independence") %>%
        generate(reps = 10, type = "permute") %>%
        calculate(stat = "diff in means", order = c("large", "small")) %>%
        visualize(direction = "both", obs_stat = obs_diff_mean),
      "deprecated"
    )
  )

  # Produces warning first for not checking conditions but would also error
  expect_error(
    expect_warning(
      iris_tbl %>%
        specify(Petal.Width ~ Sepal.Width.Group) %>%
        hypothesize(null = "independence") %>%
        generate(reps = 100, type = "permute") %>%
        calculate(stat = "diff in means", order = c("large", "small")) %>%
        visualize(method = "both", direction = "both", obs_stat = obs_diff_mean)
    )
  )

  expect_doppelganger(
    "vis-theor-both-1",
    expect_warning(
      iris_tbl %>%
        specify(Petal.Width ~ Sepal.Width.Group) %>%
        hypothesize(null = "independence") %>%
        generate(reps = 100, type = "permute") %>%
        calculate(stat = "diff in means", order = c("large", "small")) %>%
        visualize(
          method = "theoretical", direction = "both", obs_stat = obs_diff_mean
        )
    )
  )

  expect_doppelganger(
    "vis-theor-both-2",
    expect_warning(
      iris_tbl %>%
        specify(Sepal.Width.Group ~ NULL, success = "small") %>%
        hypothesize(null = "point", p = 0.8) %>%
#         generate(reps = 100, type = "simulate") %>%
#         calculate(stat = "z") %>%
        visualize(
          method = "theoretical",
          obs_stat = 2, # Should probably update
          direction = "both"
        )
    )
  )

  expect_doppelganger(
    "vis-sim-left-1",
    expect_warning(
      iris_tbl %>%
        specify(Petal.Width ~ NULL) %>%
        hypothesize(null = "point", mu = 1.3) %>%
        generate(reps = 100, type = "bootstrap") %>%
        calculate(stat = "mean") %>%
        visualize(direction = "left", obs_stat = mean(iris$Petal.Width)),
      "deprecated"
    )
  )
})

test_that("mirror_obs_stat works", {
  expect_equal(mirror_obs_stat(1:10, 4), c(`60%` = 6.4))
})

test_that("obs_stat as a data.frame works", {
  mean_petal_width <- iris_tbl %>%
    specify(Petal.Width ~ NULL) %>%
    calculate(stat = "mean")
  expect_doppelganger(
    "df-obs_stat-1",
    expect_warning(
      iris_tbl %>%
        specify(Petal.Width ~ NULL) %>%
        hypothesize(null = "point", mu = 4) %>%
        generate(reps = 100, type = "bootstrap") %>%
        calculate(stat = "mean") %>%
        visualize(obs_stat = mean_petal_width),
      "deprecated"
    )
  )
  
  mean_df_test <- data.frame(x = c(4.1, 1), y = c(1, 2))
  expect_doppelganger(
    "df-obs_stat-2",
    expect_warning(
      iris_tbl %>%
        specify(Petal.Width ~ NULL) %>%
        hypothesize(null = "point", mu = 4) %>%
        generate(reps = 100, type = "bootstrap") %>%
        calculate(stat = "mean") %>%
        visualize(obs_stat = mean_df_test)
    )
  )
})

test_that('method = "both" behaves nicely', {
  # stop_glue(
  #   '`generate()` and `calculate()` are both required to be done prior ',
  #   'to `visualize(method = "both")`'
  # )
  expect_error(
    iris_tbl %>%
      specify(Petal.Width ~ NULL) %>%
      hypothesize(null = "point", mu = 4) %>%
      generate(reps = 100, type = "bootstrap") %>%
#       calculate(stat = "mean") %>%
      visualize(method = "both")
  )

  expect_doppelganger(
    "method-both",
    expect_warning(
      iris_tbl %>%
        specify(Petal.Width ~ Sepal.Length.Group) %>%
        hypothesize(null = "point", mu = 4) %>%
        generate(reps = 10, type = "bootstrap") %>%
        calculate(stat = "t", order = c(">5", "<=5")) %>%
        visualize(method = "both")
    )
  )
})

test_that("Traditional right-tailed tests have warning if not right-tailed", {
  expect_warning(
    iris_tbl %>%
      specify(Sepal.Width.Group ~ Species, success = "large") %>%
      hypothesize(null = "independence") %>%
      generate(reps = 100, type = "permute") %>%
      calculate(stat = "Chisq") %>%
      visualize(method = "both", obs_stat = 2, direction = "left")
  )
  expect_warning(
    iris_tbl %>%
      specify(Sepal.Length ~ Species) %>%
      hypothesize(null = "independence") %>%
      generate(reps = 100, type = "permute") %>%
      calculate(stat = "F") %>%
      visualize(method = "both", obs_stat = 2, direction = "two_sided")
  )
  expect_warning(
    iris_tbl %>%
      specify(Sepal.Width.Group ~ Species, success = "large") %>%
      hypothesize(null = "independence") %>%
#       generate(reps = 100, type = "permute") %>%
      calculate(stat = "Chisq") %>%
      visualize(method = "theoretical", obs_stat = 2, direction = "left")
  )
  expect_warning(
    iris_tbl %>%
      specify(Sepal.Length ~ Species) %>%
      hypothesize(null = "independence") %>%
#       generate(reps = 100, type = "permute") %>%
      calculate(stat = "F") %>%
      visualize(method = "theoretical", obs_stat = 2, direction = "two_sided")
  )
})

test_that("confidence interval plots are working", {
  iris_boot <- iris_tbl %>%
    specify(Sepal.Width.Group ~ Sepal.Length.Group, success = "large") %>%
    generate(reps = 100) %>%
    calculate(stat = "diff in props", order = c(">5", "<=5"))

  df_error <- tibble::tibble(col1 = rnorm(5), col2 = rnorm(5))
  vec_error <- 1:10

  perc_ci <- iris_boot %>% get_ci()

  expect_error(iris_boot %>% visualize(endpoints = df_error))

  expect_warning(iris_boot %>% visualize(endpoints = vec_error))

  expect_doppelganger(
    "ci-vis",
    expect_warning(
      iris_boot %>% visualize(endpoints = perc_ci, direction = "between"),
      "deprecated"
    )
  )

  expect_warning(iris_boot %>% visualize(obs_stat = 3, endpoints = perc_ci))
})

test_that("title adapts to not hypothesis testing workflow", {
  set.seed(100)
  iris_boot_tbl <- iris_tbl %>% 
    specify(response = Sepal.Width) %>% 
    generate(reps = 100, type = "bootstrap")
  
  expect_doppelganger(
    "vis-no-hypothesize-sim",
    iris_boot_tbl %>% 
      calculate(stat = "mean") %>%
      visualize()
  )
  expect_doppelganger(
    "vis-no-hypothesize-both",
    expect_warning(
      iris_boot_tbl %>% 
        calculate(stat = "t") %>%
        visualize(method = "both")
    )
  )
})

test_that("warn_right_tail_test works", {
  expect_warn_right_tail <- function(stat_name) {
    warn_regex <- paste0(stat_name, ".*right-tailed")
    
    expect_silent(warn_right_tail_test(NULL, stat_name))
    expect_silent(warn_right_tail_test("right", stat_name))
    expect_warning(warn_right_tail_test("left", stat_name), warn_regex)
    expect_warning(warn_right_tail_test("two_sided", stat_name), warn_regex)
  }
  
  expect_warn_right_tail("F")
  expect_warn_right_tail("Chi-Square")
})
