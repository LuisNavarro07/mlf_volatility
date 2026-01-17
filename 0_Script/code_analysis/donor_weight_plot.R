library(pacman)
p_load(tidyverse, rio, here, janitor)
rm(list = ls())
base_path = here::here('/Users/lunavarr/Library/CloudStorage/OneDrive-UW/Research/MLF_Volatility')

format_plot <- function(graph){
  # Format the Graph
  fontsize = 16
  formatted_plot <- graph + 
    theme_few() + scale_color_wsj() + scale_fill_wsj() +
    theme(axis.text.x = element_text(angle = 0, size = fontsize, face = "plain")) + 
    theme(axis.text.y = element_text(angle = 0, size = fontsize, face = "plain")) + 
    theme(axis.title.x = element_text(size = fontsize, face = "plain")) +
    theme(axis.title.y = element_text(size = fontsize, face = "plain")) +
    theme(legend.text = element_text(size = fontsize , face = "plain", hjust = 0))+
    theme(legend.title = element_blank())+
    theme(legend.background = element_blank())+
    theme(legend.position = "top", legend.justification = "left")+
    theme(plot.title = element_text(angle = 0, size = fontsize + 3, face = "bold", hjust = 0))+ 
    theme(plot.subtitle = element_text(angle = 0, size = fontsize + 1, face = "italic", hjust = 0)) + 
    theme(panel.border = element_rect(color = "black", fill = NA, linewidth = 1)) +
    theme(axis.line = element_line()) + 
    theme(strip.text = element_text(size = fontsize + 2)) + 
    theme(panel.grid.major.x = element_line(color = "gray90", linetype = "dashed")) + 
    theme(panel.grid.major.y = element_line(color = "gray90", linetype = "dashed")) + 
    theme(axis.text.x.bottom = element_text(angle = 0))
  return(formatted_plot)
}


# Function to Export Graphs 
save_graph <- function(graph, name, size = "small"){
  
  if(size == "big"){
    cowplot::ggsave2(filename = name, 
                     plot = graph, dpi = 200, 
                     width = 40, height = 60, units = "cm")
  } else {
    cowplot::ggsave2(filename = name, 
                     plot = graph, dpi = 200, 
                     width = 40, height = 20, units = "cm")
  } 
}

path_out = here(base_path, '2_Output')
folder = 'baseline'

clean_donor_names <- function(data){
  df <- data %>% 
    mutate(name_clean = case_when(
      # --- Currencies (Rows 1-22) ---
      name == "DEXBZUS" ~ "Currency: Brazilian Real to U.S. Dollar",
      name == "DEXCAUS" ~ "Currency: Canadian Dollar to U.S. Dollar",
      name == "DEXCHUS" ~ "Currency: Chinese Yuan to U.S. Dollar",
      name == "DEXDNUS" ~ "Currency: Danish Krone to U.S. Dollar",
      name == "DEXHKUS" ~ "Currency: Hong Kong Dollar to U.S. Dollar",
      name == "DEXINUS" ~ "Currency: Indian Rupee to U.S. Dollar",
      name == "DEXJPUS" ~ "Currency: Japanese Yen to U.S. Dollar",
      name == "DEXKOUS" ~ "Currency: South Korean Won to U.S. Dollar",
      name == "DEXMAUS" ~ "Currency: Malaysian Ringgit to U.S. Dollar",
      name == "DEXMXUS" ~ "Currency: Mexican Peso to U.S. Dollar",
      name == "DEXNOUS" ~ "Currency: Norwegian Krone to U.S. Dollar",
      name == "DEXSDUS" ~ "Currency: Swedish Krona to U.S. Dollar",
      name == "DEXSFUS" ~ "Currency: South African Rand to U.S. Dollar",
      name == "DEXSIUS" ~ "Currency: Singapore Dollar to U.S. Dollar",
      name == "DEXSLUS" ~ "Currency: Sri Lankan Rupee to U.S. Dollar",
      name == "DEXSZUS" ~ "Currency: Swiss Franc to U.S. Dollar",
      name == "DEXTAUS" ~ "Currency: Taiwan Dollar to U.S. Dollar",
      name == "DEXTHUS" ~ "Currency: Thai Baht to U.S. Dollar",
      name == "DEXUSAL" ~ "Currency: U.S. Dollar to Australian Dollar",
      name == "DEXUSEU" ~ "Currency: U.S. Dollar to Euro",
      name == "DEXUSNZ" ~ "Currency: U.S. Dollar to New Zealand Dollar",
      name == "DEXUSUK" ~ "Currency: U.S. Dollar to U.K. Pound Sterling",
      
      # --- Stock Indices & Commodities (Rows 23-102) ---
      name == "aexindex" ~ "Stock Market Index: Netherlands",
      name == "as51index" ~ "Stock Market Index: Australia",
      name == "aseindex" ~ "Stock Market Index: Greece",
      name == "atxindex" ~ "Stock Market Index: Austria",
      name == "bel20index" ~ "Stock Market Index: Belgium",
      name == "bo1comdty" ~ "Commodity Price: Soybean Oil",
      name == "bsxindex" ~ "Stock Market Index: Bermuda",
      name == "buxindex" ~ "Stock Market Index: Hungary",
      name == "cacindex" ~ "Stock Market Index: France",
      name == "cc1comdty" ~ "Commodity Price: Cocoa",
      name == "clacomdty" ~ "Commodity Price: Crude Oil", 
      name == "coacomdty" ~ "Commodity Price: Brent",
      name == "coalinequity" ~ "Commodity Price: Coal",
      name == "croxindex" ~ "Stock Market Index: Croatia",
      name == "ctbef3ygovt" ~ "Sovereign Bond: Belgium (3Y)",
      name == "ctbrl3ygovt" ~ "Sovereign Bond: Brazil (3Y)",
      name == "ctbrl5ygovt" ~ "Sovereign Bond: Brazil (5Y)",
      name == "ctbrlii30tgovt" ~ "Sovereign Bond: Brazil (30Y)",
      name == "ctchf10ygovt" ~ "Sovereign Bond: Switzerland (10Y)",
      name == "ctclp10ygovt" ~ "Sovereign Bond: Chile (10Y)",
      name == "ctczk3ygovt" ~ "Sovereign Bond: Czech (3Y)",
      name == "ctdemii5y" ~ "Sovereign Bond: Germany (5Y)",
      name == "ctdkk3ygovt" ~ "Sovereign Bond: Denmark (3Y)",
      name == "ctdkk5ygovt" ~ "Sovereign Bond: Denmark (5Y)",
      name == "cteurlt2ygvot" ~ "Sovereign Bond: Lithuania (2Y)",
      name == "cteurro6ygovt" ~ "Sovereign Bond: Romania (6Y)",
      name == "ctfrf9ygovt" ~ "Sovereign Bond: France (9Y)",
      name == "ctgbp10ygovt" ~ "Sovereign Bond: England (10Y)",
      name == "ctgbpii5ygovt" ~ "Sovereign Bond: England (5Y)",
      name == "ctgrd20ygovt" ~ "Sovereign Bond: Greece (20Y)",
      name == "ctiep3ygovt" ~ "Sovereign Bond: Ireland (3Y)",
      name == "ctjmd10ygovt" ~ "Sovereign Bond: Jamaica (10Y)",
      name == "ctlvl2ygovt" ~ "Sovereign Bond: Latvia (2Y)",
      name == "ctmxn10ygovt" ~ "Sovereign Bond: Mexico (10Y)",
      name == "ctnok3ygovt" ~ "Sovereign Bond: Norway (3Y)",
      name == "ctnzd5ygovt" ~ "Sovereign Bond: New Zealand (5Y)",
      name == "ctpln2ygovt" ~ "Sovereign Bond: Poland (2Y)",
      name == "ctsek10ygovt" ~ "Sovereign Bond: Sweden (10Y)",
      name == "ctxeurindex" ~ "Stock Market Index: Czesch",
      name == "ctzar10ygovt" ~ "Sovereign Bond: South Africa (10Y)",
      name == "daxindex" ~ "Stock Market Index: Germany",
      name == "dl1comdty" ~ "Commodity Price: Ethanol",
      name == "fc1comdty" ~ "Commodity Price: Feeder Cattle",
      name == "ftsemibindex" ~ "Stock Market Index: Italy",
      name == "gc1comdty" ~ "Commodity Price: Gold",
      name == "hexindex" ~ "Stock Market Index: Finland",
      name == "hg1comdty" ~ "Commodity Price: Copper",
      name == "hisindex" ~ "Stock Market Index: Hong Kong",
      name == "ho1comdty" ~ "Commodity Price: Heating Oil",
      name == "ibexindex" ~ "Stock Market Index: Spain",
      name == "icexiindex" ~ "Stock Market Index: Iceland",
      name == "igpaindex" ~ "Stock Market Index: Chile",
      name == "induindex" ~ "Commodity Price: Indu",
      name == "jo1comdty" ~ "Commodity Price: Orange Juice",
      name == "kc1comdty" ~ "Commodity Price: Coffee",
      name == "kospiindex" ~ "Stock Market Index: South Korea",
      name == "kse100index" ~ "Stock Market Index: Pakistan",
      name == "lb1comdty" ~ "Commodity Price: Lumber",
      name == "lc1comdty" ~ "Commodity Price: Live Cattle",
      name == "lh1comdty" ~ "Commodity Price: Lean Hogs",
      name == "mexbolindex" ~ "Stock Market Index: Mexico",
      name == "ng1comdty" ~ "Commodity Price: Natural Gas",
      name == "nse200index" ~ "Stock Market Index: Kenya",
      name == "omxc25index" ~ "Stock Market Index: Denmark",
      name == "omxindex" ~ "Stock Market Index: Sweden",
      name == "or1comdty" ~ "Commodity Price: Rubber",
      name == "qs1comdty" ~ "Commodity Price: Gasoil",
      name == "rotxlindex" ~ "Stock Market Index: Romania",
      name == "rr1comdty" ~ "Commodity Price: Rough Rice",
      name == "rs1comdty" ~ "Commodity Price: Canola",
      name == "rtsiindex" ~ "Stock Market Index: Russia",
      name == "saxindex" ~ "Stock Market Index: Slovakia",
      name == "sensexindex" ~ "Stock Market Index: India",
      name == "si1comdty" ~ "Commodity Price: Silver",
      name == "sm1comdty" ~ "Commodity Price: Soybean Meal",
      name == "smiindex" ~ "Stock Market Index: Switzerland",
      name == "spxindex" ~ "Stock Market Index: United States",
      name == "utxeurindex" ~ "Stock Market Index: Ukraine",
      name == "xb1comdty" ~ "Commodity Price: Gasoline",
      name == "xptusdcurrncy" ~ "Commodity Price: Platinum",
      TRUE ~ as.character(name) # Fallback just in case
    )) %>% 
    mutate(
      short_name = name_clean %>%
        # Remove the specific asset class prefixes at the start of the string
        str_remove("^(Currency: |Sovereign Bond: |Price)") %>%
        # Replace "U.S. Dollar" with "USD"
        str_replace_all("U.S. Dollar", "USD")
    )
  return(df)
}
# Donor names 
donor_names <- rio::import(here(base_path, '1_Data', 'Clean', 'synth_clean_fixedcr.dta')) %>% 
  filter(varlab != "Municipal Bonds" & asset_class != "Outcome") %>% 
  distinct(id, varlab, name, asset_class, .keep_all = FALSE) %>% clean_donor_names()
  
clean_weights <- function(data){
  df <- data %>% 
    janitor::clean_names() %>% 
    left_join(
      donor_names %>% 
        select(id, short_name, name_clean) %>% rename(donor_id = id), by = 'donor_id', relationship = 'many-to-one'
    ) %>% 
    mutate(rating = case_when(
      id == 1 ~ "A", 
      id == 2 ~ "AA", 
      id == 3 ~ "AAA", 
      id == 4 ~ "BBB"
    ) %>% as.factor()) %>% 
    filter(is.na(donor_id) == FALSE)
    
   return(df) 
}

#- Read data 
create_donor_weight_plot <- function(folder){

    sdid_weights <- rio::import(here(path_out, folder, 'sdid_results.dta')) %>% 
    clean_weights() %>% 
    select(id, donor_id, weight, asset_class, short_name, name_clean, rating) 
  
  # donors by rating 
  sdid_weights %>% 
    filter(weight >0) %>% 
    group_by(rating) %>% dplyr::summarize(n = n())
  donor_weight_plot <- sdid_weights %>% 
    filter(weight >0) %>% 
    mutate(rating = factor(rating, levels = c('AAA', 'AA', 'A', 'BBB'))) %>% 
    ggplot(mapping = aes(x = reorder(short_name, weight), 
                         y = weight, fill = rating, color = rating, shape = rating)) + 
    geom_hline(yintercept = 0, color = 'gray20', linetype = 'dashed') + 
    geom_point(size = 3) + 
    labs(y = 'Unit Weights', x = '', 
         title = 'Donor Weights') + 
    scale_y_continuous(labels = scales::percent_format(), n.breaks = 20) 
  
  donor_weight_plot <- format_plot(donor_weight_plot) + 
    theme(axis.text.x.bottom = element_text(size = 7, angle = 90)) + 
    theme(legend.position = c(0.01, 0.90))
  
  save_graph(
    graph = donor_weight_plot, 
    name = here(path_out, folder,  'donor_weight_plot.pdf'), 
    size = 'small'
  )
  
  # top 10 donors 
  donor_weight_plot_top10 <- sdid_weights %>% 
    filter(weight >0) %>% 
    group_by(id, rating) %>% 
    arrange(id, -weight) %>% 
    mutate(rank = percent_rank(weight)) %>% 
    slice_max(order_by = rank, prop = 0.10) %>% 
    mutate(rating = factor(rating, levels = c('AAA', 'AA', 'A', 'BBB'))) %>% 
    ggplot(mapping = aes(y = reorder(name_clean, weight), 
                         x = weight, fill = rating, color = rating, shape = rating)) + 
    geom_vline(xintercept = 0, color = 'gray20', linetype = 'dashed') + 
    geom_point(size = 3) + 
    labs(x = 'Unit Weights', y = '', 
         title = 'Donor Weights (Top 10 Donors)') + 
    scale_x_continuous(labels = scales::percent_format(), n.breaks = 20) 
  
  donor_weight_plot_top10 <- format_plot(donor_weight_plot_top10) + 
    theme(legend.position = c(0.90, 0.10))
  
  save_graph(
    graph = donor_weight_plot_top10, 
    name = here(path_out, folder,  'donor_weight_plot_top10.pdf'), 
    size = 'small'
  )
  
  
  return(list(donor_weight_plot, donor_weight_plot_top10))
}

donor_weight_baseline <- create_donor_weight_plot(folder = 'baseline')

donor_weight_res_out <- create_donor_weight_plot(folder = 'res_out')

donor_weight_res_spread <- create_donor_weight_plot(folder = 'res_spread')

donor_weight_spread <- create_donor_weight_plot(folder = 'spread')

donor_weight_weighted_res_spread <- create_donor_weight_plot(folder = 'weighted_res_spread')

donor_weight_weighted_yield <- create_donor_weight_plot(folder = 'weighted_yield')

# -----------------------------------------------------------------------------

# Weights Table 
weights_list_table <- rio::import(here(path_out, 'baseline', 'sdid_results.dta')) %>% 
  clean_weights() %>% 
  select(rating, weight, asset_class, name_clean) %>% 
  mutate(weight = scales::percent(weight,accuracy = 0.01)) %>% 
  spread(rating, weight) %>% 
  arrange(asset_class, name_clean) %>% 
  select(-asset_class) %>% 
  relocate(name_clean, `AAA`, `AA`, `A`, `BBB`)

print(xtable::xtable(weights_list_table))

# Donor Composition 
folder = 'baseline'

create_donor_composition <- function(folder){
  
  sdid_weights <- rio::import(here(path_out, folder, 'sdid_results.dta')) %>% 
    janitor::clean_names() %>% 
    select(id, donor_id, weight, asset_class, varlab, name) %>% 
    left_join(
      donor_names %>% 
        select(id, short_name, name_clean) %>% rename(donor_id = id), by = 'donor_id', relationship = 'many-to-one'
    )%>% 
    mutate(rating = case_when(
      id == 1 ~ "A", 
      id == 2 ~ "AA", 
      id == 3 ~ "AAA", 
      id == 4 ~ "BBB"
    ) %>% as.factor()) %>% 
    filter(is.na(donor_id) == FALSE) 
  
  sdid_composition <- sdid_weights %>% 
    group_by(rating, asset_class) %>% 
    dplyr::summarize(
      weight = sum(weight, na.rm = TRUE)
    ) %>% 
    mutate(order = case_when(
      rating == 'AAA' ~ 1, 
      rating == 'AA' ~ 2, 
      rating == 'A' ~ 3, 
      rating == 'BBB' ~ 4
    )) %>% 
    ggplot(mapping = aes(x = weight, y = reorder(asset_class, weight))) + 
    facet_wrap(~reorder(rating, order), nrow = 2, ncol = 2, scales = 'free') +
    geom_col(position = 'stack', color = 'black', alpha = 0.75) + 
    geom_text(aes(label = scales::percent(weight, accuracy = 0.01)), 
              position = position_stack(vjust = 1.2), 
              size = 3)+
    labs(x = 'Unit Weight', y = '') + 
    scale_x_continuous(n.breaks = 7, labels = scales::percent_format()) +
    coord_cartesian(xlim = c(0, 0.65))
  
  sdid_composition <- format_plot(sdid_composition)
  
  save_graph(
    graph = sdid_composition, 
    name = here(path_out, folder,  'sdid_composition.pdf'), 
    size = 'small'
  )
  
  return(sdid_composition)
}

donor_composition_baseline <- create_donor_composition(folder = 'baseline')

# -----------------------------------------------------------------------------
# Leave one out: weight stability 
sdid_weights_baseline <- rio::import(here(path_out, 'baseline', 'sdid_results.dta')) %>% 
  clean_weights()   %>% 
  group_by(rating, asset_class) %>% 
  dplyr::summarize(
    Baseline = sum(weight, na.rm = TRUE)
  ) 
  

sdid_weights_loa <- rio::import(here(path_out, 'leave_one_out', 'sdid_att_results_leave_out.dta')) %>% 
  clean_weights()  

weights_comp_loa_plot <- sdid_weights_loa %>% 
  filter(weight > 0) %>% 
  group_by(id, rating, leave_id, asset_class) %>% 
  dplyr::summarize(weight_class = sum(weight)) %>% 
  ungroup() %>% 
  group_by(rating, asset_class) %>% 
  dplyr::summarize(
    Mean = mean(weight_class), 
    SD = sd(weight_class), 
    P01 = quantile(weight_class, na.rm = TRUE, probs = 0.01), 
    P05 = quantile(weight_class, na.rm = TRUE, probs = 0.05), 
    P10 = quantile(weight_class, na.rm = TRUE, probs = 0.10), 
    P90 = quantile(weight_class, na.rm = TRUE, probs = 0.90), 
    P95 = quantile(weight_class, na.rm = TRUE, probs = 0.95), 
    P99 = quantile(weight_class, na.rm = TRUE, probs = 0.99), 
    ) %>% 
  left_join(
    sdid_weights_baseline, by = c('rating', 'asset_class'), 
    relationship = 'one-to-one'
  ) %>% 
  relocate(rating, asset_class, Baseline) %>% 
  mutate(order = case_when(
    rating == 'AAA' ~ 1, 
    rating == 'AA' ~ 2, 
    rating == 'A' ~ 3, 
    rating == 'BBB' ~ 4
  )) %>% 
  arrange(order, -`Baseline`) %>% 
  select(-c(order))


print(xtable::xtable(weights_comp_loa_plot, digits = 3), 
      file = here(path_out, 'baseline',  'sdid_weights_comparison.tex'))



