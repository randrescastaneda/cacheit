# cacheit &ndash; A Stata package to cache results of other commands

**cacheit** is a Stata program which allows for the full output and returned elements of commands to be saved (cached), and reloaded in the future without re-running the command. When cacheit is used, it will check if a command has previously been cached by the user, and if so reload all elements returned by the command, along with command output, without re-running the command itself.  Otherwise, if no previously cached result for the command exists, **cacheit** will run the command, and cache all output and returns for future uses.  

**cacheit** is useful if slow or resource intensive commands are run more than once, as after the first time they are run all output can be simply accessed from the previously saved version, saving on all processing time.  **cacheit** works with all valid Stata commands and is issued as a prefix before the desired command.

**cacheit** stores for future loading all elements returned or otherwise altered by the command including (where relevant):

+ All elements of the ereturn, sreturn, or return list including functions
+ Graphical output
+ Any alterations to data (unless `nodata` is specified)
+ Any alterations to any frames in memory (unless `nodata` is specified)

For examples, refer to the Example section below.

## Installation

### From SSC

You may find the stable, though slightly older, version of **cacheit** on SSC. 
```s
ssc install cacheit
```

### From GitHub 

You may find the latest version of **cacheit** on GitHub, which is updated more frequently than the SSC version.  The GitHub version may contain new features and bug fixes not yet available on SSC. 
We recommend installing the [github](https://github.com/haghish/github) Stata command by [E. F. Haghish](https://github.com/haghish)

```s
net install github, from("https://haghish.github.io/github/")
github install randrescastaneda/cacheit
```

## Syntax
```s
cacheit [subcommand, options] : anycommand 
```

where optional sub-commands are:

+ clean: Cleans all previously cached commands and any saved elements.
+ list: Lists all currently cached commands.

and options are:

+ dir(string): Specifies the directory where cached contents of commands will be saved to be restored later.  If not specified, a subdirectory of the current working directory named `_cache` is used by default.
+ project(string):  Allows for sub-folders within the cache directory if further control of cached contents is desired.
+ prefix(string): By default, all cached contents of a command will be saved with a prefix of `_ch` followed by the hash of the command as typed, along with the data signature of data in memory.  The prefix option will replace `_ch` with the indicated string
+ nodata: If `nodata` is specified, cacheit will save all command returns, but will not save data if any changes in data are detected.  
+ datacheck(string): Allows for data on disk to be checked to ensure command uniqueness.
+ framecheck(string): Allows for additional frames to be checked to ensure command uniqueness.
+ external_api(string): When using commands that retrieve data from external APIs, pass a unique identifier (e.g., version number, timestamp, API response hash) to incorporate into the cache key so that different API states produce distinct caches.
+ rngcache: By default, the random-number generator (RNG) state is ignored when constructing the cache key. Specify `rngcache` to include the current RNG state in the cache key, ensuring commands with randomness (bootstrap, simulate, random splits) produce distinct caches for different RNG states.
+ clear: Allows command implementation to proceed even if this would unsaved changes in data (similar, for example, to `use, clear`)
+ hidden: Instead of returning hidden elements as visible stored results re-hides any hidden elements. 
+ hidden_dir: Use a hidden cache subdirectory named `.cache` instead of the default `_cache`.
+ replace: Forces cacheit to re-run the command and re-cache results, even if a previously cached version of command output has been found.  Such an example may be useful if commands are re-issued and command behaviour has changed.
+ keepall: Indicates that elements stored by previous commands in e(return) and s(return) lists should not be cleared prior to invoking the command requested with cacheit, allowing for their future use.



## Examples
### A Basic Example 
As a first example, consider a regression using Stata's auto dataset.  Provided this has not previously been cached, **cacheit** will run the command as normal, with elements saved into the ereturn, return and sreturn lists:

```s
cacheit: reg price weight length
Command is not cached.  Implementing and caching for future.

      Source |       SS           df       MS      Number of obs   =        74
-------------+----------------------------------   F(2, 71)        =     18.91
       Model |   220725280         2   110362640   Prob > F        =    0.0000
    Residual |   414340116        71  5835776.28   R-squared       =    0.3476
-------------+----------------------------------   Adj R-squared   =    0.3292
       Total |   635065396        73  8699525.97   Root MSE        =    2415.7

------------------------------------------------------------------------------
       price | Coefficient  Std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
      weight |   4.699065   1.122339     4.19   0.000     2.461184    6.936946
      length |  -97.96031    39.1746    -2.50   0.015    -176.0722   -19.84838
       _cons |   10386.54   4308.159     2.41   0.019     1796.316    18976.76
------------------------------------------------------------------------------

. return list

macros:
          r(call_hash) : "_ch3875265801"
      r(datasignature) : "74:12(71728):3831085005:1395876116"
           r(cmd_hash) : "_ch2053929229"

matrices:
              r(table) :  9 x 3

. ereturn list

scalars:
                  e(N) =  74
               e(df_m) =  2
               e(df_r) =  71
                  e(F) =  18.91138982106364
                 e(r2) =  .3475630724239045
               e(rmse) =  2415.735142695644
                e(mss) =  220725280.2661347
                e(rss) =  414340115.8554869
               e(r2_a) =  .3291845674217611
                 e(ll) =  -679.9123590332625
               e(ll_0) =  -695.7128688987767
               e(rank) =  3

macros:
            e(cmdline) : "regress price weight length"
              e(title) : "Linear regression"
          e(marginsok) : "XB default"
                e(vce) : "ols"
             e(depvar) : "price"
                e(cmd) : "regress"
         e(properties) : "b V"
            e(predict) : "regres_p"
              e(model) : "ols"
          e(estat_cmd) : "regress_estat"

matrices:
                  e(b) :  1 x 3
                  e(V) :  3 x 3
               e(beta) :  1 x 2

functions:
             e(sample)   

. sreturn list

macros:
         s(width_col1) : "13"
              s(width) : "78"


```

Now imagine that some other commands are run (eg `sum price` below), such that elements in the return lists have changed, and you wish to re-gain access to these previous elements returned from the regression command.  Rather than re-running the regression, you can simply call **cacheit** once again, and it will recover all previously returned elements rather than re-running the command:

```s
sum price

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
       price |         74    6165.257    2949.496       3291      15906

return list

scalars:
                  r(N) =  74
              r(sum_w) =  74
               r(mean) =  6165.256756756757
                r(Var) =  8699525.974268788
                 r(sd) =  2949.495884768919
                r(min) =  3291
                r(max) =  15906
                r(sum) =  456229

cacheit: reg price weight length
Command was cached.  Recovering previous output.

      Source |       SS           df       MS      Number of obs   =        74
-------------+----------------------------------   F(2, 71)        =     18.91
       Model |   220725280         2   110362640   Prob > F        =    0.0000
    Residual |   414340116        71  5835776.28   R-squared       =    0.3476
-------------+----------------------------------   Adj R-squared   =    0.3292
       Total |   635065396        73  8699525.97   Root MSE        =    2415.7

------------------------------------------------------------------------------
       price | Coefficient  Std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
      weight |   4.699065   1.122339     4.19   0.000     2.461184    6.936946
      length |  -97.96031    39.1746    -2.50   0.015    -176.0722   -19.84838
       _cons |   10386.54   4308.159     2.41   0.019     1796.316    18976.76
------------------------------------------------------------------------------

return list

scalars:
              r(level) =  95
       r(PT_k_ctitles) =  1
      r(PT_has_cnotes) =  0
      r(PT_has_legend) =  0

macros:
          r(call_hash) : "_ch3875265801"
      r(datasignature) : "74:12(71728):3831085005:1395876116"
           r(cmd_hash) : "_ch2053929229"

matrices:
              r(table) :  9 x 3
                 r(PT) :  3 x 6

ereturn list

scalars:
                  e(N) =  74
               e(df_m) =  2
               e(df_r) =  71
                  e(F) =  18.91139030456543
                 e(r2) =  .3475630581378937
               e(rmse) =  2415.735107421875
                e(mss) =  220725280
                e(rss) =  414340128
               e(r2_a) =  .3291845619678497
                 e(ll) =  -679.912353515625
               e(ll_0) =  -695.712890625
               e(rank) =  3

macros:
          e(estat_cmd) : "regress_estat"
              e(model) : "ols"
            e(predict) : "regres_p"
         e(properties) : "b V"
                e(cmd) : "regress"
             e(depvar) : "price"
                e(vce) : "ols"
          e(marginsok) : "XB default"
        e(marginsprop) : "minus"
              e(title) : "Linear regression"
            e(cmdline) : "regress price weight length"

matrices:
                  e(b) :  1 x 3
                  e(V) :  3 x 3
               e(beta) :  1 x 2

functions:
             e(sample)   

```
Note that command output is also echoed to the terminal which is loaded from a previous log.

### An Example with Time Tests
As a second example, and to see the benefits of **cacheit**, consider a command which may take considerable time to run, such as a bootstrap procedure.  While the first time it is cached the command will need to run, in future calls it will run essentiall instantaneously:

```s
sysuse auto
(1978 automobile data)

timer on 1

cacheit: bootstrap, reps(5000) dots(100): reg price mpg
Command is not cached.  Implementing and caching for future.
(running regress on estimation sample)

Bootstrap replications (5,000): .........1,000.........2,000.........3,000.........4,000.........5,000 done

Linear regression                                    Number of obs =        74
                                                     Replications  =     5,000
                                                     Wald chi2(1)  =     16.89
                                                     Prob > chi2   =    0.0000
                                                     R-squared     =    0.2196
                                                     Adj R-squared =    0.2087
                                                     Root MSE      = 2623.6529

------------------------------------------------------------------------------
             |   Observed   Bootstrap                         Normal-based
       price | coefficient  std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
         mpg |  -238.8943   58.12175    -4.11   0.000    -352.8109   -124.9778
       _cons |   11253.06   1378.934     8.16   0.000       8550.4    13955.72
------------------------------------------------------------------------------

timer off 1

timer on 2

cacheit: bootstrap, reps(5000) dots(100): reg price mpg
Command was cached.  Recovering previous output.
(running regress on estimation sample)

Bootstrap replications (5,000): .........1,000.........2,000.........3,000.........4,000.........5,000 done

Linear regression                                    Number of obs =        74
                                                     Replications  =     5,000
                                                     Wald chi2(1)  =     16.89
                                                     Prob > chi2   =    0.0000
                                                     R-squared     =    0.2196
                                                     Adj R-squared =    0.2087
                                                     Root MSE      = 2623.6529

------------------------------------------------------------------------------
             |   Observed   Bootstrap                         Normal-based
       price | coefficient  std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
         mpg |  -238.8943   58.12175    -4.11   0.000    -352.8109   -124.9778
       _cons |   11253.06   1378.934     8.16   0.000       8550.4    13955.72
------------------------------------------------------------------------------

timer off 2

timer list
   1:     33.83 /        1 =      33.8310
   2:      0.04 /        1 =       0.0450
```

### An Example with Graphs
Finally, note that this also works for commands that issue multiple graphs.  As an example, consider the following command which produces two graphs (this requires sdid from the SSC).  First, we will run the command, and examine graphs in memory (graphs will also be produced in interactive versions of Stata).
```s
webuse set www.damianclarke.net/stata/

webuse prop99_example.dta, clear

cacheit: sdid packspercapita state year treated, vce(placebo) seed(1213) graph g1on
Command is not cached.  Implementing and caching for future.
Placebo replications (50). This may take some time.
----+--- 1 ---+--- 2 ---+--- 3 ---+--- 4 ---+--- 5
..................................................     50


Synthetic Difference-in-Differences Estimator

-----------------------------------------------------------------------------
packsperca~a |     ATT     Std. Err.     t      P>|t|    [95% Conf. Interval]
-------------+---------------------------------------------------------------
     treated | -15.60383    9.87941    -1.58    0.114   -34.96712     3.75946
-----------------------------------------------------------------------------
95% CIs and p-values are based on large-sample approximations.
Refer to Arkhangelsky et al., (2021) for theoretical derivations.

graph dir
    g1_1989  g2_1989
```
Now, we will drop graphs, and re-run with **cacheit** and confirm that the command is printed from **cacheit** and graphs have been re-loaded in memory (and re-displayed in interactive versions of Stata).

```s
graph drop _all

cacheit: sdid packspercapita state year treated, vce(placebo) seed(1213) graph g1on
Command was cached.  Recovering previous output.
Placebo replications (50). This may take some time.
----+--- 1 ---+--- 2 ---+--- 3 ---+--- 4 ---+--- 5
..................................................     50


Synthetic Difference-in-Differences Estimator

-----------------------------------------------------------------------------
packsperca~a |     ATT     Std. Err.     t      P>|t|    [95% Conf. Interval]
-------------+---------------------------------------------------------------
     treated | -15.60383    9.87941    -1.58    0.114   -34.96712     3.75946
-----------------------------------------------------------------------------
95% CIs and p-values are based on large-sample approximations.
Refer to Arkhangelsky et al., (2021) for theoretical derivations.

graph dir
    g1_1989  g2_1989
```

### Use of cacheit sub-commands
Based on the above commands, we can examine sub-commands within cacheit.  Below we use `cacheit list` which provides a list of all currently cached commands.

```{s}
. cacheit list
Cached commands: 
reg price weight length

reg price weight length

bootstrap, reps(5000) dots(100): reg price mpg

sdid packspercapita state year treated, vce(placebo) seed(1213) graph g1on
```

We can also use `cacheit clean` to remove all cached commands and related saved elements, and confirm that no commands are stored in the cache:

```{s}
. cacheit clean
Warning: This will delete all files within ~/home/_cache
Do you want to continue? (y/n): . y

. cacheit list
Cached commands: 
```

## Global control
Standard cache behaviour can also be controlled by using a number of global variables. Specifically, the following globals can be set, and if these are set, these will override any default behaviour.  

| Global name | Value | Description |
| ----------- | ----- | ----------- |
|cache_replace | replace| Automatically activates the replace option, overwriting the cache each time.|
|cache_keepall | keepall | Automatically activates the keepall option, preserving previous return lists. |
|cache_on      | off   | Bypasses caching entirely (effectively ignoring the _cacheit:_ prefix if present). |
|cache_prefix  | string | Define a prefix for saving cached contents, overriding the default *_ch* used in the prefix option with any *string* defined by the user. |
|cache_dir | dir_name | Define a default location for saving cached contents, overriding the default  *_cache* directory with any *dir_name* defined by the user. |
| cache_project | dir_name | Define a default location within the cache directory to store cached output with any *dir_name* |

This allows for permanent control of cacheit for the entire duration a global is set.
If such global control is detected by cacheit, a note will be provided to users warning that global
control is detected.  Note that if both global control is set *and* a command option is set,
the command option will be take primacy.  For example, if the cache_project global is set to 
*my_sub_project*, all cached commands will be stored in a directory named in this fashion. 
However if a specific call to cacheit then also indicates *project(my_main_project)*, this 
specific cached command will be placed in the my_main_project directory.


## Authors

**R.Andres Castaneda**  
The World Bank  
acastanedaa@worldbank.org

**Damian Clarke**  
The University of Chile and The University of Exeter 
dclarke@fen.uchile.cl

