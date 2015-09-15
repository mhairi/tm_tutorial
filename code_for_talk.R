###################################
#Loading in the data and cleaning #
###################################

library(tm)

reviews <- read.csv("reviews.csv", stringsAsFactors=FALSE)

#setting up source and corpus
review_source <- VectorSource(reviews$text)
corpus <- Corpus(review_source)

# Making my own inspection function
inspect <- function(corpus, i = 200) substr(corpus[[1]][1], 1, i)

#Cleaning
inspect(corpus)
corpus <- tm_map(corpus, content_transformer(tolower))
inspect(corpus)
corpus <- tm_map(corpus, removePunctuation)
inspect(corpus)
corpus <- tm_map(corpus, stripWhitespace)
inspect(corpus)
corpus <- tm_map(corpus, removeWords, stopwords("english"))
inspect(corpus)
corpus <- tm_map(corpus, stemDocument)
inspect(corpus)

###################################
# Finding the most frequent terms #
###################################

#Making a document-term matrix
dtm <- DocumentTermMatrix(corpus)

#Finding the most frequent terms
frequency <- colSums(as.matrix(dtm))
frequency <- sort(frequency, decreasing=TRUE)

# As a word-cloud
library(wordcloud)
wordcloud(names(frequency)[1:100], frequency[1:100])

#####################
# Find Associations #
#####################

findAssocs(dtm, terms = c('game', 'broke', 'cat'), corlimit = 0.2)


##############################
# Which words predict rating #
##############################


dtm_small <- removeSparseTerms(dtm, 0.99)

model <- lm(reviews$rating ~ .,
            data = as.data.frame(as.matrix(dtm_small)))

library(dplyr)
library(ggplot2)

coefs <- 
summary(model)$coefficients %>%
  as.data.frame() %>%
  add_rownames('word') %>%         # convert rowname to variable
  slice(-1) %>%                    # remove intercept
  subset(`Pr(>|t|)` < 0.001) %>%   # only significant terms
  mutate(order = order(Estimate),  # make into ordered factor
         word  = factor(word, levels = word[order])) 
         
ggplot(coefs) +
  aes(x = word, y = Estimate,  fill = Estimate) +
  geom_bar(stat="identity", position = 'dodge') +
  scale_fill_gradientn(colours=brewer.pal(10, "Spectral"), name="Effect size") +
  coord_flip() +
  xlab("Word") +
  ylab("\nEffect Size")


#####################################
# Finding terms unique to a country #
#####################################

#Combining all the reviews from one country together
by_country <- 
  reviews %>%
  group_by(location) %>%
  summarise(text = paste(text, collapse = ' '))

review_source <- VectorSource(by_country$text)
corpus <- Corpus(review_source)

#Cleaning
corpus <- tm_map(corpus, content_transformer(tolower))
corpus <- tm_map(corpus, removePunctuation)
corpus <- tm_map(corpus, stripWhitespace)
corpus <- tm_map(corpus, removeWords, stopwords("english"))

# Make document term matrix, weighted by TF-IDF
dtm <- DocumentTermMatrix(corpus)
dtm <- removeSparseTerms(dtm, 0.3)
dtm <- as.matrix(dtm)

# Find top terms for each country
top_terms <- lapply(1:4, function(i) names(sort(dtm[i,], decreasing = TRUE))[1:10])
names(top_terms) <- by_country$location
top_terms
