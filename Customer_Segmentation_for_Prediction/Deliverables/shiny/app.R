# =========================================
# Minimal Shiny: PAM (Gower) + Saved per-cluster models
# Target: growth_rate of GigaSpire, CSC & Engagement Cloud
# =========================================
if (!requireNamespace("shiny", quietly = TRUE)) install.packages("shiny")
if (!requireNamespace("cluster", quietly = TRUE)) install.packages("cluster")
if (!requireNamespace("plotly", quietly = TRUE)) install.packages("plotly")
if (!requireNamespace("randomForest", quietly = TRUE)) install.packages("randomForest")
if (!requireNamespace("gbm", quietly = TRUE)) install.packages("gbm")
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
if (!requireNamespace("readr", quietly = TRUE)) install.packages("readr")
if (!requireNamespace("forcats", quietly = TRUE)) install.packages("forcats")

library(shiny)
library(cluster)
library(plotly)
library(randomForest)
library(gbm)
library(dplyr)
library(readr)
library(forcats)

# ----------------- Helpers -----------------
preprocess_data <- function(df) {
  # Drop X, ACCOUNT_ID from modeling copy (we keep raw for hover/download)
  df <- df %>% 
    dplyr::select(-dplyr::any_of(c("X", "ACCOUNT_ID"))) 
  # Chars -> factors
  df <- df %>% mutate(across(where(is.character), as.factor))
  # Sanitize two known factors
  if ("BUSINESS_TYPE_PRIMARY" %in% names(df)) df$BUSINESS_TYPE_PRIMARY <- factor(gsub("[^A-Za-z0-9]", "_", df$BUSINESS_TYPE_PRIMARY))
  if ("REGION" %in% names(df)) df$REGION <- factor(gsub("[^A-Za-z0-9]", "_", df$REGION))
  # Lump levels
  if ("REGION" %in% names(df)) df$REGION <- fct_lump_n(df$REGION, n = 10, other_level = "Other")
  if ("BUSINESS_TYPE_PRIMARY" %in% names(df)) df$BUSINESS_TYPE_PRIMARY <- fct_lump_n(df$BUSINESS_TYPE_PRIMARY, n = 8, other_level = "Other")
  df
}

defaults_from <- function(df, feats) {
  setNames(lapply(feats, function(f) {
    if (!f %in% names(df)) return(NA)
    v <- df[[f]]
    if (is.numeric(v)) {
      round(median(v, na.rm = TRUE), 3)
    } else if (is.factor(v)) {
      levels(v)[1]
    } else {
      sort(unique(v))[1]
    }
  }), feats)
}

ui_inputs <- function(df, feats, defs) {
  lapply(feats, function(f) {
    if (!f %in% names(df)) return(NULL)
    if (is.numeric(df[[f]])) {
      numericInput(f, f, value = as.numeric(defs[[f]]))
    } else {
      choices <- if (is.factor(df[[f]])) levels(df[[f]]) else sort(unique(df[[f]]))
      selectInput(f, f, choices = choices, selected = defs[[f]])
    }
  })
}

coerce_row <- function(input_list, ref_df, feats) {
  out <- lapply(feats, function(f) {
    val <- input_list[[f]]
    if (is.numeric(ref_df[[f]])) {
      as.numeric(val)
    } else if (is.factor(ref_df[[f]])) {
      factor(val, levels = levels(ref_df[[f]]))
    } else {
      as.character(val)
    }
  })
  df <- as.data.frame(out, check.names = FALSE, stringsAsFactors = FALSE)
  colnames(df) <- feats
  for (f in feats) {
    if (is.factor(ref_df[[f]])) df[[f]] <- factor(df[[f]], levels = levels(ref_df[[f]]))
  }
  df
}

align_types <- function(new_df, ref_df, feats) {
  for (f in feats) {
    if (!f %in% names(ref_df)) next
    if (is.factor(ref_df[[f]])) {
      new_df[[f]] <- factor(new_df[[f]], levels = levels(ref_df[[f]]))
    } else if (is.numeric(ref_df[[f]])) {
      new_df[[f]] <- suppressWarnings(as.numeric(new_df[[f]]))
    } else {
      new_df[[f]] <- as.character(new_df[[f]])
    }
  }
  new_df
}

assign_medoid <- function(one_row, medoid_profiles) {
  cf <- colnames(medoid_profiles)
  x <- one_row[, cf, drop = FALSE]
  for (nm in cf) {
    if (is.factor(medoid_profiles[[nm]])) x[[nm]] <- factor(x[[nm]], levels = levels(medoid_profiles[[nm]]))
  }
  m <- as.matrix(daisy(rbind(medoid_profiles, x), metric = "gower"))
  which.min(m[nrow(m), 1:nrow(medoid_profiles)])
}

assign_dataset <- function(df, medoid_profiles) {
  cf <- colnames(medoid_profiles)
  sub <- df[, cf, drop = FALSE]
  for (nm in cf) {
    if (is.factor(medoid_profiles[[nm]])) sub[[nm]] <- factor(sub[[nm]], levels = levels(medoid_profiles[[nm]]))
  }
  m <- as.matrix(daisy(rbind(medoid_profiles, sub), metric = "gower"))
  K <- nrow(medoid_profiles); n <- nrow(sub)
  max.col(-m[(K + 1):(K + n), 1:K, drop = FALSE])
}

# ----------------- UI -----------------
ui <- fluidPage(
  titlePanel(textOutput("title_txt")),
  sidebarLayout(
    sidebarPanel(
      h4("Upload data and bundle"),
      fileInput("data_csv", "/data/final/.csv", accept = ".csv"),
      fileInput("pam_rds",  "/outputs/pam_bundles/.rds", accept = ".rds"),
      tags$hr(),
      h4("Step 1 - Clustering features"),
      uiOutput("cluster_inputs"),
      fluidRow(
        column(6, actionButton("assign", "Assign Cluster")),
        column(6, actionButton("reset1", "Reset Step 1"))
      ),
      uiOutput("cluster_msg"),
      conditionalPanel(
        condition = "output.hasCluster == true",
        tags$hr(),
        h4("Step 2 - Prediction features"),
        uiOutput("model_inputs"),
        fluidRow(
          column(6, actionButton("predict", "Predict Target")),
          column(6, actionButton("reset2", "Reset Step 2"))
        )
      ),
      
      
      tags$hr(),
      h4("Highlight an account_id 3D"),
      selectizeInput(
        inputId = "account_id",
        label   = "ACCOUNT_ID",
        choices = NULL,               # start empty; server will fill after data loads
        multiple = FALSE,
        options = list(placeholder = "Select an ACCOUNT_ID...")
      ),
      
      tags$hr(),
      downloadButton("dl", "Download dataset with Cluster")
    ),
    mainPanel(
      h4("Segmentation"), textOutput("assign_txt"),
      h4("Prediction"), textOutput("pred_txt"),
      h4("Medoid profiles"), tableOutput("med_tbl"),
      h4("3D MDS (clustering)"), plotlyOutput("plot3d", height="80vh")
    )
  )
)

# ----------------- Server -----------------
server <- function(input, output, session) {
  # Load
  bundle <- reactive({ req(input$pam_rds); readRDS(input$pam_rds$datapath) })
  data_raw <- reactive({ req(input$data_csv); read_csv(input$data_csv$datapath, show_col_types = FALSE) |> as.data.frame() })
  data_prep <- reactive({ req(data_raw()); preprocess_data(data_raw()) })
  
  target_name <- reactive({
    tn <- bundle()$target_name
    tn <- as.character(tn)[1]
    if (is.na(tn) || !nzchar(tn)) "prediction" else tn
  })
  output$title_txt <- renderText({
    sprintf("%s - PAM (Gower) + saved per-cluster models", target_name())
  })
  
  # Bundle parts
  medoids <- reactive({
    mp <- as.data.frame(bundle()$medoid_profiles, stringsAsFactors = FALSE)
    if (is.null(colnames(mp)) || any(colnames(mp) == "")) colnames(mp) <- as.character(bundle()$cluster_feature)
    mp
  })
  
  # Fallback to medoid colnames if cluster_feature is NULL/empty
  cf <- reactive({
    cf0 <- bundle()$cluster_feature
    if (is.null(cf0) || length(cf0) == 0) colnames(medoids()) else as.character(cf0)
  })
  
  f_c1 <- reactive({ as.character(bundle()$topN_c1) })
  f_c2 <- reactive({ as.character(bundle()$topN_c2) })
  mod1 <- reactive({ bundle()$model_c1 })
  mod2 <- reactive({ bundle()$model_c2 })
  nt2  <- reactive({ as.integer(bundle()$model_c2_gbm_n_trees) })
  
  # State
  rv <- reactiveValues(def = NULL, cl = NULL)
  observeEvent(list(data_prep(), bundle()), {
    feats <- sort(unique(c(cf(), f_c1(), f_c2())))
    rv$def <- defaults_from(data_prep(), feats)
    rv$cl <- NULL
    output$assign_txt <- renderText("")
    output$pred_txt <- renderText("")
  })
  
  # Step 1 UI
  output$cluster_inputs <- renderUI({
    req(data_prep(), rv$def)
    do.call(tagList, ui_inputs(data_prep(), cf(), rv$def))
  })
  
  observeEvent(input$assign, {
    valid_cf <- intersect(cf(), colnames(medoids()))
    req(length(valid_cf) > 0)
    
    row_cf <- coerce_row(input, data_prep(), valid_cf)
    
    rv$cl <- assign_medoid(
      row_cf[, valid_cf, drop = FALSE],
      medoids()[, valid_cf, drop = FALSE]
    )
    
    output$assign_txt <- renderText(paste("Cluster", rv$cl))
  })
  
  output$cluster_msg <- renderUI({
    if (is.null(rv$cl)) em("No cluster yet.") else strong(paste("Cluster:", rv$cl))
  })
  output$hasCluster <- reactive(!is.null(rv$cl))
  outputOptions(output, "hasCluster", suspendWhenHidden = FALSE)
  
  # Step 2 UI
  model_feats <- reactive({
    req(rv$cl)
    setdiff(if (rv$cl == 1) f_c1() else f_c2(), cf())
  })
  output$model_inputs <- renderUI({
    req(data_prep(), rv$def, model_feats())
    do.call(tagList, ui_inputs(data_prep(), model_feats(), rv$def))
  })
  
  # Reset buttons
  observeEvent(input$reset1, {
    req(rv$def, data_prep())
    for (f in cf()) {
      v <- rv$def[[f]]; if (is.null(v)) next
      if (is.numeric(data_prep()[[f]])) updateNumericInput(session, f, value = as.numeric(v))
      else updateSelectInput(session, f, selected = v)
    }
    rv$cl <- NULL
    output$assign_txt <- renderText("")
    output$pred_txt <- renderText("")
  })
  
  observeEvent(input$reset2, {
    req(rv$def, data_prep(), rv$cl)
    for (f in model_feats()) {
      v <- rv$def[[f]]; if (is.null(v)) next
      if (is.numeric(data_prep()[[f]])) updateNumericInput(session, f, value = as.numeric(v))
      else updateSelectInput(session, f, selected = v)
    }
    output$pred_txt <- renderText("")
  })
  
  # Label for printing model type in the UI
  label_model <- function(m) {
    if (inherits(m, "gbm"))           return("GBM")
    if (inherits(m, "randomForest"))  return("Random Forest")
    paste(class(m)[1], collapse = "/")
  }
  
  # n.trees for GBM (both clusters), if provided in bundle
  nt1 <- reactive({ as.integer(bundle()$model_c1_gbm_n_trees) })
  nt2 <- reactive({ as.integer(bundle()$model_c2_gbm_n_trees) })
  
  # Predict
  # ---- Predict (dynamic target + dynamic model) ----
  observeEvent(input$predict, {
    req(rv$cl, data_prep())
    feats <- if (rv$cl == 1) f_c1() else f_c2()
    one   <- coerce_row(input, data_prep(), unique(c(cf(), feats)))
    x     <- align_types(one[, feats, drop = FALSE], data_prep(), feats)
    
    model <- if (rv$cl == 1) mod1() else mod2()
    lbl   <- label_model(model)
    
    y <- tryCatch({
      if (inherits(model, "gbm")) {
        nt <- if (rv$cl == 1) nt1() else nt2()
        if (length(nt) == 0 || is.na(nt)) nt <- if (!is.null(model$n.trees)) model$n.trees else 100L
        predict(model, newdata = x, n.trees = nt, type = "response")
      } else if (inherits(model, "randomForest")) {
        predict(model, newdata = x)
      } else {
        # generic fallback
        predict(model, newdata = x)
      }
    }, error = function(e) NA_real_)
    
    output$pred_txt <- renderText({
      if (is.na(y)[1]) {
        sprintf("Cluster %s prediction failed.", rv$cl)
      } else {
        sprintf("Cluster %s - %s: %s = %.6f", rv$cl, lbl, target_name(), as.numeric(y))
      }
    })
  })
  
  # Dataset assignment + download
  assigned <- reactive({
    req(data_prep(), data_raw())
    
    valid_cf <- intersect(colnames(medoids()), names(data_prep()))
    req(length(valid_cf) > 0)
    
    cl <- assign_dataset(
      data_prep()[, valid_cf, drop = FALSE],
      medoids()[, valid_cf, drop = FALSE]
    )
    
    out <- data_raw()  # keep raw columns (incl. ACCOUNT_ID)
    out$Cluster <- factor(cl)
    out
  })
  output$dl <- downloadHandler(
    filename = function() "dataset_with_clusters.csv",
    content  = function(file) write.csv(assigned(), file, row.names = FALSE)
  )
  
  observeEvent(assigned(), {
    dfp <- assigned()
    if ("ACCOUNT_ID" %in% names(dfp)) {
      updateSelectizeInput(session, "account_id",
                           choices = sort(unique(as.character(dfp$ACCOUNT_ID))),
                           server = TRUE)
    }
  })
  
  # Medoids + 3D plot
  output$med_tbl <- renderTable({
    cbind(Cluster = seq_len(nrow(medoids())), medoids())
  })
  
  output$plot3d <- renderPlotly({
    req(assigned(), data_prep())
    cfv <- intersect(cf(), names(data_prep()))
    if (length(cfv) < 2) {
      return(plot_ly(type = "scatter3d", mode = "markers"))
    }
    
    nr   <- coerce_row(input, data_prep(), cfv)
    comb <- rbind(data_prep()[, cfv, drop = FALSE],
                  nr[, cfv, drop = FALSE])
    
    dist_obj <- cluster::daisy(comb, metric = "gower")
    coords   <- stats::cmdscale(dist_obj, k = 3)
    
    # Ensure numeric matrix with 3 columns
    coords <- as.matrix(coords)
    if (ncol(coords) < 3) coords <- cbind(coords, Z = 0)
    
    pts <- coords[1:nrow(data_prep()), , drop = FALSE]   # dataset points
    usr <- coords[nrow(coords), , drop = FALSE]          # user's Step 1 inputs
    
    dfp <- assigned()   # has Cluster and (if provided) ACCOUNT_ID
    lev <- levels(dfp$Cluster)
    if (is.null(lev)) lev <- sort(unique(as.character(dfp$Cluster)))
    pal <- c("#E69F00","#56B4E9","#009E73","#F0E442",
             "#0072B2","#CC79A7","#999999")[seq_along(lev)]
    
    p <- plot_ly(type = "scatter3d", mode = "markers")
    
    has_id <- "ACCOUNT_ID" %in% names(dfp)
    for (i in seq_along(lev)) {
      idx <- which(as.character(dfp$Cluster) == as.character(lev[i]))
      if (length(idx) == 0) next
      
      x <- as.numeric(pts[idx, 1])
      y <- as.numeric(pts[idx, 2])
      z <- as.numeric(pts[idx, 3])
      
      txt <- if (has_id) {
        paste0("Cluster: ", lev[i], "<br>ACCOUNT_ID: ", dfp$ACCOUNT_ID[idx])
      } else {
        paste0("Cluster: ", lev[i])
      }
      
      p <- add_trace(
        p,
        x = x, y = y, z = z,
        name = paste("Cluster", lev[i]),
        marker = list(size = 4, color = pal[i]),
        hoverinfo = "text",
        text = txt,
        showlegend = TRUE
      )
    }
    
    # Add the user's current input point (red diamond)
    p <- add_trace(
      p,
      x = as.numeric(usr[1]),
      y = as.numeric(usr[2]),
      z = as.numeric(usr[3]),
      name = "Your Input",
      marker = list(size = 9, color = "red", symbol = "diamond",
                    line = list(width = 2, color = "black")),
      hoverinfo = "text",
      text = "Your Input",
      showlegend = TRUE
    )
    
    # --- Highlight an ACCOUNT_ID from the uploaded dataset (no halo) ---
    if (!is.null(input$account_id) && nzchar(input$account_id) && has_id) {
      id_vec <- as.character(dfp$ACCOUNT_ID)
      idx_id <- which(id_vec == as.character(input$account_id))
      
      if (length(idx_id) > 0) {
        # Coords and hover text
        hx <- as.numeric(pts[idx_id, 1])
        hy <- as.numeric(pts[idx_id, 2])
        hz <- as.numeric(pts[idx_id, 3])
        cl_lbl <- as.character(dfp$Cluster[idx_id])
        htxt <- paste0("Cluster: ", cl_lbl, "<br>ACCOUNT_ID: ", id_vec[idx_id])
        
        # Main highlighted point (color-blind–safe vermillion star), NO HALO
        p <- add_trace(
          p,
          x = hx, y = hy, z = hz,
          name = "Highlighted ACCOUNT_ID",
          marker = list(
            size = 7,
            color = "#CC79A7",     # Vermillion (color‑blind safe)
            symbol = "diamond",
            line = list(width = 1.5, color = "white"),
            opacity = 1            # ensure no transparency
          ),
          hoverinfo = "text",
          text = htxt,
          showlegend = TRUE
        )
      }
    }
    
    # Axis labels and title
    p <- layout(
      p,
      scene = list(
        domain = list(x=c(0,1), y=c(0,0.86)),
        xaxis = list(title = "Dim 1"),
        yaxis = list(title = "Dim 2"),
        zaxis = list(title = "Dim 3")
      ),
      margin = list(l=0, r=0, b=200, t=8),
      title = list(text="3D MDS of Clustering (Gower)", 
                   x=0.5, xanchor = "center", 
                   y=1, yanchor = "top", 
                   pad = list(t = 6, b = 14, l = 0, r = 0)),
      
      legend = list(
        orientation = "h",
        x = 0.5, y = 0.90,              # above plot
        xanchor = "center", yanchor = "bottom",
        bgcolor = "rgba(255,255,255,0.0)",
        font = list(size = 11)
      )
      
    )
    
    p
  })
}

shinyApp(ui, server)