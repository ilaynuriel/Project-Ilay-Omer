%%%-------------------------------------------------------------------
%%% @author Omer
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. Oct 2020 14:20
%%%-------------------------------------------------------------------
-module(mapreduce).
-author("Ilay-Omer").



-record(movie_data, {id, title, original_title, year,
  date_published, genre, duration, country, language, director,
  writer, production_company, actors, description, avg_vote,
  votes, budget, usa_gross_income, worlwide_gross_income,
  metascore, reviews_from_users, reviews_from_critics}).
-record(query,
{
  type,
  searchVal,
  searchCategory,
  resultCategory = #movie_data{}
}).
%%-record(numOfResults, {number}).

%% API
-export([get/2]).


%% get - return the values according to the request
get(TableName, Query = #query{}) ->
  % mapping the values by the searchCategory, searchVal
  case ets:file2tab(TableName) of
    {ok, Table} ->
      Ans = map(Table, Query),
      ets:delete(Table),
      Ans;
    _ -> table_error
  end.

%% map -
% generic map - searching searchVal in searchCategory.
map(Table, Query = #query{type = generic, searchVal = SearchVal}) ->
  reduce(
    case Query#query.searchCategory of
      "Title" ->
        [Movie || {_id, Movie} <- ets:tab2list(Table), string:str(Movie#movie_data.title, SearchVal) > 0];
      "Year" ->
        [Movie || {_id, Movie} <- ets:tab2list(Table), Movie#movie_data.year == SearchVal];
      "Genre" ->
        [Movie || {_id, Movie} <- ets:tab2list(Table), string:str(Movie#movie_data.genre, SearchVal) > 0];
      % note: range of +-5
      "Duration" -> [Movie || {_id, Movie} <- ets:tab2list(Table),
        list_to_integer(Movie#movie_data.duration) > list_to_integer(SearchVal) - 5,
        list_to_integer(Movie#movie_data.duration) < list_to_integer(SearchVal) + 5];
      "Country" ->
        [Movie || {_id, Movie} <- ets:tab2list(Table), string:str(Movie#movie_data.country, SearchVal) > 0];
      "Language" ->
        [Movie || {_id, Movie} <- ets:tab2list(Table), string:str(Movie#movie_data.language, SearchVal) > 0];
      "Director" ->
        [Movie || {_id, Movie} <- ets:tab2list(Table), string:str(Movie#movie_data.director, SearchVal) > 0];
      "Writer" ->
        [Movie || {_id, Movie} <- ets:tab2list(Table), string:str(Movie#movie_data.writer, SearchVal) > 0];
      "Production Company" ->
        [Movie || {_id, Movie} <- ets:tab2list(Table), string:str(Movie#movie_data.production_company, SearchVal) > 0];
      "Actor" ->
        [Movie || {_id, Movie} <- ets:tab2list(Table), string:str(Movie#movie_data.actors, SearchVal) > 0];
      "Description" ->
        [Movie || {_id, Movie} <- ets:tab2list(Table), string:str(Movie#movie_data.description, SearchVal) > 0];
      % note: range of +-0.5
      "Score" ->
      case string:str(SearchVal, ".") > 0 of
          true -> % it's a float
            [Movie || {_id, Movie} <- ets:tab2list(Table),
              Movie#movie_data.avg_vote > float_to_list(list_to_float(SearchVal) - 0.6),
              Movie#movie_data.avg_vote < float_to_list(list_to_float(SearchVal) + 0.5)];
          false -> % it's an integer
            [Movie || {_id, Movie} <- ets:tab2list(Table),
              Movie#movie_data.avg_vote >= float_to_list(list_to_integer(SearchVal) - 0.6),
              Movie#movie_data.avg_vote < float_to_list(list_to_integer(SearchVal) + 0.5)]
        end;
      "Budget" ->
        [Movie || {_id, Movie} <- ets:tab2list(Table), string:str(Movie#movie_data.budget, SearchVal) > 0];
      _ -> []
    end, Query);


% OTHER map - ????
map(_Table, _Query = #query{}) ->
  % DO SOMETHING...
  anotherquery.


%% reduce -
% generic reduce - taking only the resultCategory.
reduce(MappedList, Query = #query{type = generic}) ->
  %% each element in list will be construct from the query.resultCategory section

  %% mapping the wanted values -
  % Condition is the resultCategory#movie_data.CATEGORY value
  % Value is the value we want to insert the table
  Fun_value = fun(Condition, Value) ->
    case Condition of
      true -> Value;
      false -> ""
    end
              end,
  Fun_moviedata_reduce = fun(Movie = #movie_data{}, Query2) ->
    #movie_data{id = Movie#movie_data.id, title = Movie#movie_data.title,
      original_title = Fun_value(Query2#query.resultCategory#movie_data.original_title, Movie#movie_data.original_title),
      year = Fun_value(Query2#query.resultCategory#movie_data.year, Movie#movie_data.year),
      date_published = Fun_value(Query2#query.resultCategory#movie_data.date_published, Movie#movie_data.date_published),
      genre = Fun_value(Query2#query.resultCategory#movie_data.genre, Movie#movie_data.genre),
      duration = Fun_value(Query2#query.resultCategory#movie_data.duration, Movie#movie_data.duration),
      country = Fun_value(Query2#query.resultCategory#movie_data.country, Movie#movie_data.country),
      language = Fun_value(Query2#query.resultCategory#movie_data.language, Movie#movie_data.language),
      director = Fun_value(Query2#query.resultCategory#movie_data.director, Movie#movie_data.director),
      writer = Fun_value(Query2#query.resultCategory#movie_data.writer, Movie#movie_data.writer),
      production_company = Fun_value(Query2#query.resultCategory#movie_data.production_company, Movie#movie_data.production_company),
      actors = Fun_value(Query2#query.resultCategory#movie_data.actors, Movie#movie_data.actors),
      description = Fun_value(Query2#query.resultCategory#movie_data.description, Movie#movie_data.description),
      avg_vote = Fun_value(Query2#query.resultCategory#movie_data.avg_vote, Movie#movie_data.avg_vote),
      votes = Fun_value(Query2#query.resultCategory#movie_data.votes, Movie#movie_data.votes),
      budget = Fun_value(Query2#query.resultCategory#movie_data.budget, Movie#movie_data.budget),
      usa_gross_income = Fun_value(Query2#query.resultCategory#movie_data.usa_gross_income, Movie#movie_data.usa_gross_income),
      worlwide_gross_income = Fun_value(Query2#query.resultCategory#movie_data.worlwide_gross_income, Movie#movie_data.worlwide_gross_income),
      metascore = Fun_value(Query2#query.resultCategory#movie_data.metascore, Movie#movie_data.metascore),
      reviews_from_users = Fun_value(Query2#query.resultCategory#movie_data.reviews_from_users, Movie#movie_data.reviews_from_users),
      reviews_from_critics = Fun_value(Query2#query.resultCategory#movie_data.reviews_from_critics, Movie#movie_data.reviews_from_critics)}
                         end,

  [Fun_moviedata_reduce(Movie, Query) || Movie = #movie_data{} <- MappedList];

% OTHER reduce - ????
reduce(_MappedList, _Query = #query{}) ->
  % DO SOMETHING...
  anotherquery.

