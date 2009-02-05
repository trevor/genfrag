# $Id: timetracker.rb,v 1.5 2005/05/09 08:43:14 wrk Exp $
# $Source: /home/cvs/opensource/lib/ruby/util/time/timetracker.rb,v $
#
# Time tracker
#
# @Author: Pjotr Prins
# @Date:   20010706
#
# Example:
#
# TimeTracker.tracktime { do_something }
#
# Info:: Pjotr's shared Ruby modules
# Author:: Pjotr Prins
# mail:: pjotr.public05@thebird.nl
# Copyright:: July 2007
# License:: Ruby License


module TimeTracker

  def TimeTracker.tracktime verbose=true, f=nil

    begin
      t1 = Time.now
      yield

      ensure

        t2 = Time.now
        dt = t2 - t1
        if verbose
          if f == nil
            f = $stdout
          end
          f.print "\nElapsed time "
          hours = dt.to_i/3600
          dt -= hours*3600
          mins  = dt.to_i/60
          dt -= mins*60
          secs  = dt
          secs = secs.to_i if secs > 25
          if hours > 0
            f.print hours.to_i," hours "
          end
          if mins > 0
            f.print mins.to_i," minutes "
          end
          f.print secs," seconds\n" 
        end
    end
  end
  
end
