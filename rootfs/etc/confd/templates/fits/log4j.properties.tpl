#------------------------------------------------------------------------------
#
#  The following properties set the logging levels and log appender.  The
#  log4j.rootCategory variable defines the default log level plus one or more
#  appenders.
#
#  To override the default (rootCategory) log level,
#  define a property of the form (see below for available values):
#
#    Available logger names:
#      CONSOLE  The command line console (defaults to standard error output)
#      FILE     The log file to write to.
#
#    Possible Log Levels:
#      ERROR - only errors during processing are logged, or FATAL.
#      WARN  - warnings, errors and fatal are logged.
#      INFO  - general info messages and all the above are logged.
#      DEBUG - more detailed messages and all the above are logged.
#      TRACE - the most detailed messages and all the above are logged.
#
#      OFF   - This will turn off logging for an appender.
#
#------------------------------------------------------------------------------

log4j.rootLogger={{getv "/fits/rootlogger/log/level"}}, CONSOLE

# create substitutions for appenders
date-pattern={yyyy-MM-dd HH:mm:ss}

#------------------------------------------------------------------------------
# direct log messages to console
#------------------------------------------------------------------------------

log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender
# Send debugging to error output so it can be differentiated from FITS file output which goes to standard out.
log4j.appender.CONSOLE.Target=System.err
log4j.appender.CONSOLE.Threshold={{getv "/fits/console/log/level"}}
log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.CONSOLE.layout.ConversionPattern=%d${date-pattern} - %5p - %c{1}:%L - %m%n
# Detailed appender for debugging, includes thread name:
# log4j.appender.CONSOLE.layout.ConversionPattern=%d${date-pattern} - %5p - [%t] %c{1}:%L - %m%n

# Java package-specific appenders
log4j.logger.uk.gov.nationalarchives.droid={{getv "/fits/uk/gov/nationalarchives/droid/log/level"}}, CONSOLE
log4j.logger.edu.harvard.hul.ois.jhove={{getv "/fits/edu/harvard/hul/ois/jhove/log/level"}}, CONSOLE
log4j.logger.org.apache.tika={{getv "/fits/org/apache/tika/log/level"}}, CONSOLE
log4j.logger.net.sf={{getv "/fits/net/sf/log/level"}}, CONSOLE
log4j.logger.org.apache.pdfbox={{getv "/fits/org/apache/pdfbox/log/level"}}, CONSOLE