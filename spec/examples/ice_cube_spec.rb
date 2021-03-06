require File.dirname(__FILE__) + '/spec_helper'

describe IceCube::Schedule, 'occurs_on?' do
  
  it 'should respond to complex combinations (1)' do
    start_date = Time.utc(2010, 1, 1)
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.yearly(2).day(:wednesday).month_of_year(:april)
    #check assumptions
    dates = schedule.occurrences(Time.utc(2011, 12, 31)) #two years
    dates.size.should == 4
    dates.each do |date|
      date.wday.should == 3
      date.month.should == 4
      date.year.should == start_date.year #since we're doing every other
    end
  end
  
  it 'should respond to a single date event' do
    start_date = Time.now
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_date(start_date + 2)
    #check assumptions
    dates = schedule.occurrences(start_date + 50)
    dates.size.should == 1
    dates[0].should == start_date + 2
  end

  it 'should not return anything when given a single date and the same exclusion date' do
    start_date = Time.now
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_date(start_date + 2)
    schedule.add_exception_date(start_date + 2)
    #check assumption
    schedule.occurrences(start_date + 50 * IceCube::ONE_DAY).size.should == 0
  end

  it 'should return properly with a combination of a recurrence and exception rule' do
    schedule = IceCube::Schedule.new(DAY)
    schedule.add_recurrence_rule IceCube::Rule.daily # every day
    schedule.add_exception_rule IceCube::Rule.weekly.day(:monday, :tuesday, :wednesday) # except these
    #check assumption - in 2 weeks, we should have 8 days
    schedule.occurrences(DAY + 13 * IceCube::ONE_DAY).size.should == 8
  end

  it 'should be able to exclude a certain date from a range' do
    start_date = Time.now
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.daily
    schedule.add_exception_date(start_date + 1 * IceCube::ONE_DAY) # all days except tomorrow
    # check assumption
    dates = schedule.occurrences(start_date + 13 * IceCube::ONE_DAY) # 2 weeks
    dates.size.should == 13 # 2 weeks minus 1 day
    dates.should_not include(start_date + 1 * IceCube::ONE_DAY)
  end

  it 'make a schedule with a start_date not included in a rule, and make sure that count behaves properly' do
    start_date = WEDNESDAY
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.weekly.day(:thursday).count(5)
    dates = schedule.all_occurrences
    dates.uniq.size.should == 5
    dates.each { |d| d.wday.should == 4 }
    dates.should_not include(WEDNESDAY)
  end

  it 'make a schedule with a start_date included in a rule, and make sure that count behaves properly' do
    start_date = WEDNESDAY + IceCube::ONE_DAY
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.weekly.day(:thursday).count(5)
    dates = schedule.all_occurrences
    dates.uniq.size.should == 5
    dates.each { |d| d.wday.should == 4 }
    dates.should include(WEDNESDAY + IceCube::ONE_DAY)
  end

  it 'should work as expected with a second_of_minute rule specified' do
    start_date = DAY
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.weekly.second_of_minute(30)
    dates = schedule.occurrences(start_date + 30 * 60)
    dates.each { |date| date.sec.should == 30 }
  end

  it 'ensure that when count on a rule is set to 0, 0 occurrences come back' do
    start_date = DAY
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.daily.count(0)
    schedule.all_occurrences.should == []
  end

  it 'should be able to be schedules at 1:st:st and 2:st:st every day' do
    start_date = Time.utc(2007, 9, 2, 9, 15, 25)
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.daily.hour_of_day(1, 2).count(6)
    dates = schedule.all_occurrences
    dates.should == [Time.utc(2007, 9, 3, 1, 15, 25), Time.utc(2007, 9, 3, 2, 15, 25),
                     Time.utc(2007, 9, 4, 1, 15, 25), Time.utc(2007, 9, 4, 2, 15, 25), 
                     Time.utc(2007, 9, 5, 1, 15, 25), Time.utc(2007, 9, 5, 2, 15, 25)]
  end

  it 'should be able to be schedules at 1:0:st and 2:0:st every day' do
    start_date = Time.utc(2007, 9, 2, 9, 15, 25)
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.daily.hour_of_day(1, 2).minute_of_hour(0).count(6)
    dates = schedule.all_occurrences
    dates.should == [Time.utc(2007, 9, 3, 1, 0, 25), Time.utc(2007, 9, 3, 2, 0, 25),
                     Time.utc(2007, 9, 4, 1, 0, 25), Time.utc(2007, 9, 4, 2, 0, 25), 
                     Time.utc(2007, 9, 5, 1, 0, 25), Time.utc(2007, 9, 5, 2, 0, 25)]
  end

  it 'will only return count# if you specify a count and use .first' do
    start_date = Time.now
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.daily.count(10)
    dates = schedule.first(200)
    dates.size.should == 10
  end

  it 'occurs yearly' do
    start_date = DAY
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.yearly
    dates = schedule.first(10)
    dates.each do |date|
      date.month.should == start_date.month
      date.day.should == start_date.day
      date.hour.should == start_date.hour
      date.min.should == start_date.min
      date.sec.should == start_date.sec
    end
  end

  it 'occurs monthly' do
    start_date = Time.now
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.monthly
    dates = schedule.first(10)
    dates.each do |date|
      date.day.should == start_date.day
      date.hour.should == start_date.hour
      date.min.should == start_date.min
      date.sec.should == start_date.sec
    end
  end
  
  it 'occurs daily' do
    start_date = Time.now
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.daily
    dates = schedule.first(10)
    dates.each do |date|
      date.hour.should == start_date.hour
      date.min.should == start_date.min
      date.sec.should == start_date.sec
    end
  end
  
  it 'occurs hourly' do
    start_date = Time.now
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.hourly
    dates = schedule.first(10)
    dates.each do |date|
      date.min.should == start_date.min
      date.sec.should == start_date.sec
    end
  end
  
  it 'occurs minutely' do
    start_date = Time.now
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.minutely
    dates = schedule.first(10)
    dates.each do |date|
      date.sec.should == start_date.sec
    end
  end

  it 'occurs every second for an hour' do
    start_date = Time.now
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.secondly.count(60)
    # build the expectation list
    expectation = []
    0.upto(59) { |i| expectation << start_date + i }
    # compare with what we get
    dates = schedule.all_occurrences
    dates.size.should == 60
    schedule.all_occurrences.should == expectation
  end

  it 'perform a every day LOCAL and make sure we get back LOCAL' do
    Time.zone = 'Eastern Time (US & Canada)'
    start_date = Time.zone.local(2010, 9, 2, 5, 0, 0)
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.daily
    schedule.first(10).each do |d| 
      d.utc?.should == false
      d.hour.should == 5
      (d.utc_offset == -5 * IceCube::ONE_HOUR || d.utc_offset == -4 * IceCube::ONE_HOUR).should be(true)
    end
  end

  it 'perform a every day LOCAL and make sure we get back LOCAL' do
    start_date = Time.utc(2010, 9, 2, 5, 0, 0)
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.daily
    schedule.first(10).each do |d| 
      d.utc?.should == true
      d.utc_offset.should == 0
      d.hour.should == 5
    end    
  end
  
  # here we purposely put a UTC time that is before the range ends, to
  # verify ice_cube is properly checking until bounds
  it 'works with a until date that is UTC, but the start date is local' do
    Time.zone = 'Eastern Time (US & Canada)'
    start_date = Time.zone.local(2010, 11, 6, 5, 0, 0)
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.daily.until(Time.utc(2010, 11, 10, 8, 0, 0)) #4 o clocal local
    #check assumptions
    dates = schedule.all_occurrences
    dates.each { |d| d.utc?.should == false }
    dates.should == [Time.zone.local(2010, 11, 6, 5, 0, 0), 
      Time.zone.local(2010, 11, 7, 5, 0, 0), Time.zone.local(2010, 11, 8, 5, 0, 0), 
      Time.zone.local(2010, 11, 9, 5, 0, 0)]
  end

  # here we purposely put a local time that is before the range ends, to
  # verify ice_cube is properly checking until bounds
  it 'works with a until date that is local, but the start date is UTC' do
    start_date = Time.utc(2010, 11, 6, 5, 0, 0)
    Time.zone = 'Eastern Time (US & Canada)'
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.daily.until(Time.zone.local(2010, 11, 9, 23, 0, 0)) #4 o UTC time
    #check assumptions
    dates = schedule.all_occurrences
    dates.each { |d| d.utc?.should == true }
    dates.should == [Time.utc(2010, 11, 6, 5, 0, 0), 
      Time.utc(2010, 11, 7, 5, 0, 0), Time.utc(2010, 11, 8, 5, 0, 0), 
      Time.utc(2010, 11, 9, 5, 0, 0)]
  end

  it 'works with a monthly rule iterating on UTC' do
    start_date = Time.utc(2010, 4, 24, 15, 45, 0)
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.monthly
    dates = schedule.first(10)
    dates.each do |d|
      d.day.should == 24
      d.hour.should == 15
      d.min.should == 45
      d.sec.should == 0
      d.utc?.should be(true)
    end
  end

  it 'can retrieve rrules from a schedule' do
    schedule = IceCube::Schedule.new(Time.now)
    rules = [IceCube::Rule.daily, IceCube::Rule.monthly, IceCube::Rule.yearly]
    rules.each { |r| schedule.add_recurrence_rule(r) }
    # pull the rules back out of the schedule and compare
    schedule.rrules.should == rules
  end

  it 'can retrieve exrules from a schedule' do
    schedule = IceCube::Schedule.new(Time.now)
    rules = [IceCube::Rule.daily, IceCube::Rule.monthly, IceCube::Rule.yearly]
    rules.each { |r| schedule.add_exception_rule(r) }
    # pull the rules back out of the schedule and compare
    schedule.exrules.should == rules
  end

  it 'can retrieve rdates from a schedule' do
    schedule = IceCube::Schedule.new(Time.now)
    dates = [Time.now, Time.now + 5, Time.now + 10]
    dates.each { |d| schedule.add_recurrence_date(d) }
    # pull the dates back out of the schedule and compare
    schedule.rdates.should == dates
  end
  
  it 'can retrieve exdates from a schedule' do
    schedule = IceCube::Schedule.new(Time.now)
    dates = [Time.now, Time.now + 5, Time.now + 10]
    dates.each { |d| schedule.add_exception_date(d) }
    # pull the dates back out of the schedule and compare
    schedule.exdates.should == dates
  end

  it 'can reuse the same rule' do
    schedule = IceCube::Schedule.new(Time.now)
    rule = IceCube::Rule.daily
    schedule.add_recurrence_rule rule
    result1 = schedule.first(10)
    rule.day(:monday)
    # check to make sure the change affected the rule
    schedule.first(10).should_not == result1
  end

  it 'ensures that month of year (3) is march' do
    schedule = IceCube::Schedule.new(DAY)
    schedule.add_recurrence_rule IceCube::Rule.daily.month_of_year(:march)
    
    schedule2 = IceCube::Schedule.new(DAY)
    schedule2.add_recurrence_rule IceCube::Rule.daily.month_of_year(3)
    
    schedule.first(10).should == schedule2.first(10)
  end

  it 'ensures that day of week (1) is monday' do
    schedule = IceCube::Schedule.new(DAY)
    schedule.add_recurrence_rule IceCube::Rule.daily.day(:monday)
    
    schedule2 = IceCube::Schedule.new(DAY)
    schedule2.add_recurrence_rule IceCube::Rule.daily.day(1)
    
    schedule.first(10).should == schedule2.first(10)
  end

  it 'should be able to find occurrences between two dates which are both in the future' do
    start_time = Time.now
    schedule = IceCube::Schedule.new(start_time)
    schedule.add_recurrence_rule IceCube::Rule.daily
    dates = schedule.occurrences_between(start_time + IceCube::ONE_DAY * 2, start_time + IceCube::ONE_DAY * 4)
    dates.should == [start_time + IceCube::ONE_DAY * 2, start_time + IceCube::ONE_DAY * 3, start_time + IceCube::ONE_DAY * 4]
  end

  it 'should be able to tell us when there is at least one occurrence between two dates' do
    start_date = WEDNESDAY
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.weekly.day(:friday)
    true.should == schedule.occurs_between?(start_date, start_date + IceCube::ONE_DAY * 3)
  end

  it 'should be able to tell us when there is no occurrence between two dates' do
    start_date = WEDNESDAY
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.weekly.day(:friday)
    false.should == schedule.occurs_between?(start_date, start_date + IceCube::ONE_DAY)
  end

  it 'should be able to determine whether a given rule falls on a Date (rather than a time) - happy path' do
    start_time = Time.local(2010, 7, 2, 10, 0, 0)
    schedule = IceCube::Schedule.new(start_time)
    schedule.add_recurrence_rule IceCube::Rule.daily.count(10)
    schedule.occurs_on?(Date.new(2010, 7, 4)).should be(true)
  end
  
  it 'should be able to determine whether a given rule falls on a Date (rather than a time)' do
    start_time = Time.local(2010, 7, 2, 10, 0, 0)
    schedule = IceCube::Schedule.new(start_time)
    schedule.add_recurrence_rule IceCube::Rule.daily.count(10)
    schedule.occurs_on?(Date.new(2010, 7, 1)).should_not be(true)
  end

  it 'should be able to get back rdates from an ice_cube schedule' do
    schedule = IceCube::Schedule.new DAY
    schedule.add_recurrence_date DAY
    schedule.add_recurrence_date(DAY + 2)
    schedule.rdates.should == [DAY, DAY + 2]
  end

  it 'should be able to get back exdates from an ice_cube schedule' do
    schedule = IceCube::Schedule.new DAY
    schedule.add_exception_date DAY
    schedule.add_exception_date(DAY + 2)
    schedule.exdates.should == [DAY, DAY + 2]
  end

  it 'occurs_on? works for a single date recurrence' do
    schedule = IceCube::Schedule.new Time.utc(2009, 9, 2, 13, 0, 0)
    schedule.add_recurrence_date Time.utc(2009, 9, 2, 13, 0, 0)
    schedule.occurs_on?(Date.new(2009, 9, 2)).should be(true)
    schedule.occurs_on?(Date.new(2009, 9, 1)).should_not be(true)
    schedule.occurs_on?(Date.new(2009, 9, 3)).should_not be(true)
  end

  it 'occurs_on? should only be(true) for the single day of a certain event' do
    Time.zone = "Pacific Time (US & Canada)"
    schedule = IceCube::Schedule.new Time.zone.parse("2010/5/13 02:00:00")
    schedule.add_recurrence_date Time.zone.parse("2010/5/13 02:00:00")
    schedule.occurs_on?(Date.new(2010, 5, 13)).should be(true)
    schedule.occurs_on?(Date.new(2010, 5, 14)).should be(false)
    schedule.occurs_on?(Date.new(2010, 5, 15)).should be(false)
  end

  it 'should allow calling of .first on a schedule with no arguments' do
    start_time = Time.now
    schedule = IceCube::Schedule.new(start_time)
    schedule.add_recurrence_date start_time
    schedule.first.should == start_time
  end

  it 'should be able to ignore nil dates that are inserted as part of a collection to add_recurrence_date' do
    start_time = Time.now
    schedule = IceCube::Schedule.new(start_time)
    schedule.add_recurrence_date start_time
    schedule.add_recurrence_date start_time + IceCube::ONE_DAY
    schedule.add_recurrence_date nil
    schedule.all_occurrences.should == [start_time, start_time + IceCube::ONE_DAY]
  end

  it 'should be able to use all_occurrences with no rules' do
    start_time = Time.now
    schedule = IceCube::Schedule.new(start_time)
    schedule.add_recurrence_date start_time
    lambda do
      schedule.all_occurrences.should == [start_time]
    end.should_not raise_error
  end

  it 'should be able to specify a duration on a schedule use occurring_at? on the schedule
      to find out if a given time is included' do
    start_time = Time.local 2010, 5, 6, 10, 0, 0
    schedule = IceCube::Schedule.new(start_time, :duration => 3600)
    schedule.add_recurrence_rule IceCube::Rule.daily
    schedule.occurring_at?(Time.local(2010, 5, 6, 10, 30, 0)).should be(true) #true
  end

  it 'should be able to specify a duration on a schedule and use occurring_at? on that schedule
      to make sure a time is not included' do
    start_time = Time.local 2010, 5, 6, 10, 0, 0
    schedule = IceCube::Schedule.new(start_time, :duration => 3600)
    schedule.add_recurrence_rule IceCube::Rule.daily
    schedule.occurring_at?(Time.local(2010, 5, 6, 9, 59, 0)).should be(false)
    schedule.occurring_at?(Time.local(2010, 5, 6, 11, 0, 1)).should be(false)
  end

  it 'should be able to specify a duration on a schedule and use occurring_at? on that schedule
      to make sure the outer bounds are included' do
    start_time = Time.local 2010, 5, 6, 10, 0, 0
    schedule = IceCube::Schedule.new(start_time, :duration => 3600)
    schedule.add_recurrence_rule IceCube::Rule.daily
    schedule.occurring_at?(Time.local(2010, 5, 6, 10, 0, 0)).should be(true)
    schedule.occurring_at?(Time.local(2010, 5, 6, 11, 0, 0)).should be(true)
  end

  it 'should be able to explicity remove a certain minute from a duration' do
    start_time = Time.local 2010, 5, 6, 10, 0, 0
    schedule = IceCube::Schedule.new(start_time, :duration => 3600)
    schedule.add_recurrence_rule IceCube::Rule.daily
    schedule.add_exception_date Time.local(2010, 5, 6, 10, 21, 30)
    schedule.occurring_at?(Time.local(2010, 5, 6, 10, 21, 29)).should be(true)
    schedule.occurring_at?(Time.local(2010, 5, 6, 10, 21, 30)).should be(false)
    schedule.occurring_at?(Time.local(2010, 5, 6, 10, 21, 31)).should be(true)
  end

  it 'should be able to specify an end time for the schedule' do
    start_time = DAY
    schedule = IceCube::Schedule.new(start_time, :end_time => DAY + IceCube::ONE_DAY * 2)
    schedule.add_recurrence_rule IceCube::Rule.daily
    schedule.all_occurrences.should == [DAY, DAY + 1*IceCube::ONE_DAY, DAY + 2*IceCube::ONE_DAY]
  end

  it 'should be able to specify an end time for the schedule and only get those on .first' do
    start_time = DAY
    # ensure proper response without the end time
    schedule = IceCube::Schedule.new(start_time)
    schedule.add_recurrence_rule IceCube::Rule.daily
    schedule.first(5).should == [DAY, DAY + 1*IceCube::ONE_DAY, DAY + 2*IceCube::ONE_DAY, DAY + 3*IceCube::ONE_DAY, DAY + 4*IceCube::ONE_DAY]
    # and then ensure that with the end time it stops it at the right day
    schedule = IceCube::Schedule.new(start_time, :end_time => DAY + IceCube::ONE_DAY * 2 + 1)
    schedule.add_recurrence_rule IceCube::Rule.daily
    schedule.first(5).should == [DAY, DAY + 1 * IceCube::ONE_DAY, DAY + 2 * IceCube::ONE_DAY]
  end

  it 'should be able to specify an end date and go to/from yaml' do
    start_time = DAY
    end_time = DAY + IceCube::ONE_DAY * 2
    schedule = IceCube::Schedule.new(start_time, :end_time => end_time)
    schedule.add_recurrence_rule IceCube::Rule.daily
    schedule2 = IceCube::Schedule.from_yaml schedule.to_yaml
    schedule2.end_time.should == end_time
  end

  it 'should be able to specify an end date for the schedule and only get those on .occurrences_between' do
    start_time = DAY
    end_time = DAY + IceCube::ONE_DAY * 2
    schedule = IceCube::Schedule.new(start_time, :end_time => end_time)
    schedule.add_recurrence_rule IceCube::Rule.daily
    expectation = [DAY, DAY + IceCube::ONE_DAY, DAY + 2*IceCube::ONE_DAY]
    schedule.occurrences_between(start_time - IceCube::ONE_DAY, start_time + 4 * IceCube::ONE_DAY).should == expectation
  end

  it 'should be able to specify an end date for the schedule and only get those on .occurrences' do
    start_time = DAY
    end_time = DAY + IceCube::ONE_DAY * 2
    schedule = IceCube::Schedule.new(start_time, :end_time => end_time)
    schedule.add_recurrence_rule IceCube::Rule.daily
    expectation = [DAY, DAY + IceCube::ONE_DAY, DAY + 2*IceCube::ONE_DAY]
    schedule.occurrences(start_time + 4 * IceCube::ONE_DAY).should == expectation
  end

  it 'should be able to work with an end date and .occurs_at' do
    start_time = DAY
    end_time = DAY + IceCube::ONE_DAY * 2
    schedule = IceCube::Schedule.new(start_time, :end_time => end_time)
    schedule.add_recurrence_rule IceCube::Rule.daily
    schedule.occurs_at?(DAY + 4*IceCube::ONE_DAY).should be(false) # out of range
  end

  it 'should be able to work with an end date and .occurs_at' do
    start_time = DAY
    end_time = DAY + IceCube::ONE_DAY * 2
    schedule = IceCube::Schedule.new(start_time, :end_time => end_time)
    schedule.add_recurrence_rule IceCube::Rule.daily
    schedule.occurs_on?((DAY + 4*IceCube::ONE_DAY)).should be(false) # out of range
  end

  it 'should be able to work with an end date and .occurring_at' do
    start_time = DAY
    end_time = DAY + IceCube::ONE_DAY * 2
    schedule = IceCube::Schedule.new(start_time, :end_time => end_time, :duration => 20)
    schedule.add_recurrence_rule IceCube::Rule.daily
    schedule.occurring_at?((DAY + 2*IceCube::ONE_DAY + 10)).should be(true) # in range
    schedule.occurring_at?((DAY + 4*IceCube::ONE_DAY + 10)).should be(false) # out of range
  end

  it 'should not create an infinite loop crossing over february - github issue 6' do
    schedule = IceCube::Schedule.new(Time.parse('2010-08-30'))
    schedule.add_recurrence_rule IceCube::Rule.monthly(6)
    schedule.occurrences_between(Time.parse('2010-07-01'), Time.parse('2010-09-01'))
  end

  it 'should be able to exist on the 28th of each month crossing over february - github issue 6a' do
    schedule = IceCube::Schedule.new(Time.local(2010, 1, 28))
    schedule.add_recurrence_rule IceCube::Rule.monthly
    schedule.first(3).should == [Time.local(2010, 1, 28), Time.local(2010, 2, 28), Time.local(2010, 3, 28)]
  end

  it 'should be able to exist on the 29th of each month crossing over february - github issue 6a' do
    schedule = IceCube::Schedule.new(Time.zone.local(2010, 1, 29))
    schedule.add_recurrence_rule IceCube::Rule.monthly
    schedule.first(3).should == [Time.zone.local(2010, 1, 29), Time.zone.local(2010, 3, 29), Time.zone.local(2010, 4, 29)]
  end

  it 'should be able to exist on the 30th of each month crossing over february - github issue 6a' do
    schedule = IceCube::Schedule.new(Time.zone.local(2010, 1, 30))
    schedule.add_recurrence_rule IceCube::Rule.monthly
    schedule.first(3).should == [Time.zone.local(2010, 1, 30), Time.zone.local(2010, 3, 30), Time.zone.local(2010, 4, 30)]
  end

  it 'should be able to exist ont he 31st of each month crossing over february - github issue 6a' do
    schedule = IceCube::Schedule.new(Time.zone.local(2010, 1, 31))
    schedule.add_recurrence_rule IceCube::Rule.monthly
    schedule.first(3).should == [Time.zone.local(2010, 1, 31), Time.zone.local(2010, 3, 31), Time.zone.local(2010, 5, 31)]
  end

  it 'should deal with a yearly rule that has februaries with different mdays' do
    schedule = IceCube::Schedule.new(Time.local(2008, 2, 29))
    schedule.add_recurrence_rule IceCube::Rule.yearly
    schedule.first(3).should == [Time.local(2008, 2, 29), Time.local(2012, 2, 29), Time.local(2016, 2, 29)]
  end

  it 'should work with every other month even when the day of the month iterating on does not exist' do
    schedule = IceCube::Schedule.new(Time.zone.local(2010, 1, 31))
    schedule.add_recurrence_rule IceCube::Rule.monthly(2)
    schedule.first(6).should == [Time.zone.local(2010, 1, 31), Time.zone.local(2010, 3, 31), Time.zone.local(2010, 5, 31), Time.zone.local(2010, 7, 31), Time.zone.local(2011, 1, 31), Time.zone.local(2011, 3, 31)]
  end

  it 'should be able to go into february and stay on the same day' do
    schedule = IceCube::Schedule.new(Time.local(2010, 1, 5))
    schedule.add_recurrence_rule IceCube::Rule.monthly
    schedule.first(2).should == [Time.local(2010, 1, 5), Time.local(2010, 2, 5)]
  end

  it 'should be able to know when to stop with an end date and a rule that misses a few times' do
    schedule = IceCube::Schedule.new(Time.local(2010, 2, 29), :end_time => Time.local(2010, 10, 30))
    schedule.add_recurrence_rule IceCube::Rule.yearly
    schedule.first(10).should == [Time.local(2010, 2, 29)]
  end

  it 'should be able to know when to stop with an end date and a rule that misses a few times' do
    schedule = IceCube::Schedule.new(Time.local(2010, 2, 29))
    schedule.add_recurrence_rule IceCube::Rule.yearly.until(Time.local(2010, 10, 30))
    schedule.first(10).should == [Time.local(2010, 2, 29)]
  end
  
  it 'should be able to know when to stop with an end date and a rule that misses a few times' do
    schedule = IceCube::Schedule.new(Time.local(2010, 2, 29))
    schedule.add_recurrence_rule IceCube::Rule.yearly.count(1)
    schedule.first(10).should == [Time.local(2010, 2, 29)]
  end

  it 'should be able to go through a year of every month on a day that does not exist' do
    schedule = IceCube::Schedule.new(Time.zone.local(2010, 1, 31), :end_time => Time.zone.local(2011, 2, 5))
    schedule.add_recurrence_rule IceCube::Rule.monthly
    schedule.all_occurrences.should == [Time.zone.local(2010, 1, 31), Time.zone.local(2010, 3, 31), Time.zone.local(2010, 5, 31),
                                 Time.zone.local(2010, 7, 31), Time.zone.local(2010, 8, 31), Time.zone.local(2010, 10, 31),
                                 Time.zone.local(2010, 12, 31), Time.zone.local(2011, 1, 31)]
  end

  it 'should be able to go through a year of every 2 months on a day that does not exist' do
    schedule = IceCube::Schedule.new(Time.zone.local(2010, 1, 31), :end_time => Time.zone.local(2011, 2, 5))
    schedule.add_recurrence_rule IceCube::Rule.monthly(2)
    schedule.all_occurrences.should == [Time.zone.local(2010, 1, 31), Time.zone.local(2010, 3, 31), Time.zone.local(2010, 5, 31),
                                        Time.zone.local(2010, 7, 31), Time.zone.local(2011, 1, 31)]
  end

  it 'should be able to go through a year of every 3 months on a day that does not exist' do
    schedule = IceCube::Schedule.new(Time.local(2010, 1, 31), :end_time => Time.local(2011, 2, 5))
    schedule.add_recurrence_rule IceCube::Rule.monthly(3)
    schedule.all_occurrences.should == [Time.local(2010, 1, 31), Time.local(2010, 7, 31), Time.local(2010, 10, 31), Time.local(2011, 1, 31)]
  end

  it 'should be able to work with occurs_on? at an odd time - start of day' do
    schedule = IceCube::Schedule.new(Time.local(2010, 8, 10, 12, 0, 0).in_time_zone('Pacific Time (US & Canada)'))
    schedule.add_recurrence_rule IceCube::Rule.weekly
    schedule.occurs_on?(Date.new(2010, 8, 10)).should be(true)
    schedule.occurs_on?(Date.new(2010, 8, 11)).should be(false)
    schedule.occurs_on?(Date.new(2010, 8, 9)).should be(false)
    schedule.occurs_on?(Date.new(2010, 8, 17)).should be(true)
  end

  it 'should be able to work with occurs_on? at an odd time - end of day' do
    schedule = IceCube::Schedule.new(Time.local(2010, 8, 10, 23, 59, 59).in_time_zone('Pacific Time (US & Canada)'))
    schedule.add_recurrence_rule IceCube::Rule.weekly
    schedule.occurs_on?(Date.new(2010, 8, 10)).should be(true)
    schedule.occurs_on?(Date.new(2010, 8, 11)).should be(false)
    schedule.occurs_on?(Date.new(2010, 8, 9)).should be(false)
    schedule.occurs_on?(Date.new(2010, 8, 17)).should be(true)
  end

  it 'should be able to work with occurs_on? at an odd time - start of day' do
    schedule = IceCube::Schedule.new(Time.local(2010, 8, 10, 0, 0, 0))
    schedule.add_recurrence_date Time.local(2010, 8, 20, 0, 0, 0)
    schedule.add_recurrence_rule IceCube::Rule.weekly
    schedule.occurs_on?(Date.new(2010, 8, 20)).should be(true)
    schedule.occurs_on?(Date.new(2010, 8, 10)).should be(true)
    schedule.occurs_on?(Date.new(2010, 8, 11)).should be(false)
    schedule.occurs_on?(Date.new(2010, 8, 17)).should be(true)
    schedule.occurs_on?(Date.new(2010, 8, 18)).should be(false)
  end

  it 'should be able to work with occurs_on? at an odd time - end of day' do
    schedule = IceCube::Schedule.new(Time.local(2010, 8, 10, 23, 59, 59).in_time_zone('Pacific Time (US & Canada)'))
    schedule.add_recurrence_date Time.local(2010, 8, 20, 23, 59, 59)
    schedule.occurs_on?(Date.new(2010, 8, 20)).should be(true)
    schedule.occurs_on?(Date.new(2010, 8, 21)).should be(false)
    schedule.occurs_on?(Date.new(2010, 8, 19)).should be(false)
  end

  it 'should work with occurs on for a single day schedule' do
    time = Time.local(2010, 8, 12, 23, 0, 0)
    date = Date.new(2010, 8, 12)
    # build the schedule
    schedule = IceCube::Schedule.new(time)
    schedule.add_recurrence_date time
    schedule.all_occurrences.should == [time]
    # test occurs_on? for surrounding dates
    schedule.occurs_on?(date).should be(true)
    schedule.occurs_on?(date + 1).should be(false)
    schedule.occurs_on?(date - 1).should be(false)
  end

  it 'should work with occurs_on? with multiple rdates' do
    schedule = IceCube::Schedule.new(Time.local(2010, 7, 10, 16))
    schedule.add_recurrence_date(Time.local(2010, 7, 11, 16))
    schedule.add_recurrence_date(Time.local(2010, 7, 12, 16))
    schedule.add_recurrence_date(Time.local(2010, 7, 13, 16))
    # test
    schedule.occurs_on?(Date.new(2010, 7, 11)).should be(true)
    schedule.occurs_on?(Date.new(2010, 7, 12)).should be(true)
    schedule.occurs_on?(Date.new(2010, 7, 13)).should be(true)
  end

  it 'should have some convenient aliases' do
    start_time = Time.now
    schedule = IceCube::Schedule.new(start_time)

    schedule.start_date.should == schedule.start_time
    schedule.end_date.should == schedule.end_time
  end

  it 'should have some convenient alias for rrules' do
    schedule = IceCube::Schedule.new(Time.now)
    daily = IceCube::Rule.daily; monthly = IceCube::Rule.monthly
    schedule.add_recurrence_rule daily
    schedule.rrule monthly
    schedule.rrules.should == [daily, monthly]
  end
  
  it 'should have some convenient alias for exrules' do
    schedule = IceCube::Schedule.new(Time.now)
    daily = IceCube::Rule.daily; monthly = IceCube::Rule.monthly
    schedule.add_exception_rule daily
    schedule.exrule monthly
    schedule.exrules.should == [daily, monthly]
  end
  
  it 'should have some convenient alias for rdates' do
    schedule = IceCube::Schedule.new(Time.now)
    schedule.add_recurrence_date Time.local(2010, 8, 13)
    schedule.rdate Time.local(2010, 8, 14)
    schedule.rdates.should == [Time.local(2010, 8, 13), Time.local(2010, 8, 14)]
  end
  
  it 'should have some convenient alias for exdates' do
    schedule = IceCube::Schedule.new(Time.now)
    schedule.add_exception_date Time.local(2010, 8, 13)
    schedule.exdate Time.local(2010, 8, 14)
    schedule.exdates.should == [Time.local(2010, 8, 13), Time.local(2010, 8, 14)]
  end

  it 'should be able to have a rule and an exrule' do
    schedule = IceCube::Schedule.new(Time.local(2010, 8, 27, 10))
    schedule.rrule IceCube::Rule.daily
    schedule.exrule IceCube::Rule.daily.day(:friday)
    schedule.occurs_on?(Date.new(2010, 8, 27)).should be(false)
    schedule.occurs_on?(Date.new(2010, 8, 28)).should be(true)
  end

  it 'should always generate the correct number of days for .first' do
    s = IceCube::Schedule.new(Time.zone.parse('1-1-1985'))
    r = IceCube::Rule.weekly(3).day(:monday, :wednesday, :friday)
    s.add_recurrence_rule(r)
    # test sizes
    s.first(3).size.should == 3
    s.first(4).size.should == 4
    s.first(5).size.should == 5
  end



  it 'should always generate the date based off the start_date_override when specified in from_yaml' do
    start_date = DAY # zero seconds
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.minutely

    start_date_override = DAY + 20

    schedule2 = IceCube::Schedule.from_yaml(schedule.to_yaml, :start_date_override => start_date_override)
    dates = schedule2.first(10)
    dates.each do |date|
      date.sec.should == start_date_override.sec
    end
  end

  it 'should always generate the date based off the start_date_override when specified in from_hash' do
    start_date = DAY # zero seconds
    schedule = IceCube::Schedule.new(start_date)
    schedule.add_recurrence_rule IceCube::Rule.minutely

    start_date_override = DAY + 20

    schedule2 = IceCube::Schedule.from_hash(schedule.to_hash, :start_date_override => start_date_override)
    dates = schedule2.first(10)
    dates.each do |date|
      date.sec.should == start_date_override.sec
    end
  end

  it 'should use current date as start date when invoked with a nil parameter' do
    schedule = IceCube::Schedule.new nil
    schedule.start_date.strftime('%d.%m.%Y').should == Time.now.strftime('%d.%m.%Y')
  end
end

