#!/opt/immune/bin/envdo python
'''
Usage: /opt/immune/bin/envdo python script_name
Author: Prashant
Updated by: PMelsen
'''
import platform
import os
import base64
from pylib import mongo,configgenerator
from mongokit import ObjectId

db = mongo.get_makalu()

def get_user_activity(result,repo_show,query_show):
	
  user_list = []
  for user in list(db.user.find({'active':True})):
    user_list.append(user['username'])
    # This function x.encode("utf-8") is used represent the unicode data.
    result.write('User: %s\n======================================================================\n' % user['username'].encode("utf-8"))
    dashboards=user['dashboard']
    dashboard = db.dereference(dashboards)
    preferences=user['preferences']
    pref = db.dereference(preferences)
    result.write('Dashboard Tabs and Widgets list:\n................................................................\n')
    result.write('Precompute: %r\n' % pref['shouldPrecompute'])
    if dashboard['active']:
      for tabs in dashboard['tabs']:
        tab = db.dereference(tabs)
        if tab['active']:
          result.write('\n ...... %s\n' % tab['name'].encode("utf-8"))
          for widget in tab["widgets"]:
            widget = db.dereference(widget)
            try:
              if widget['active']:
                result.write('\t%s / %s\n' % (tab['name'].encode("utf-8"), widget['name'].encode("utf-8")))
                livesearch = db.dereference(widget["livesearch"])
	      #if query_show:
              	if livesearch:
               	  result.write('\t-----------------------------------------\n\tQuery: %s\n' % livesearch['query'].encode("utf-8"))
                  time=[livesearch['timerange_day'],livesearch['timerange_hour'],livesearch['timerange_minute']]
                  result.write('\tTime(day:hour:min): %s\n' % time)
                  if repo_show:
                    result.write('\tRepos: %s\n' % livesearch['repos'])
                  settings=widget['settings']
                  result.write('\tType: %s\n' % settings['type'])
                  result.write('\t-----------------------------------------\n\n')
                  
            except:
              print 'Skipping widget'

    result.write('\nList of Alerts:\n....................................................................\n')
    for alerts in db.alertrules.find({'user':user['username'],'active':True}):
      result.write('\t%s\n'%alerts['name'])
      if alerts["livesearch"]:
        livesearch = db.livesearch.find_one({'_id': ObjectId(alerts['livesearch'])})
      #if query_show:
      if livesearch:
      	result.write('\t-----------------------------------------\n\tQuery: %s\n' % livesearch['query'].encode("utf-8"))
        condition=alerts['condition']
        result.write('\tCondition: %s %s\n' % (condition['condition_option'], condition['condition_value']))
        for note in alerts['notifications']:
           result.write('\tResponse type: %s\n' % note['type'])
           if note['type'] == "email":
              result.write('\tRecipients: %s\n' % note['email_emails'])
       	time=[livesearch['timerange_day'],livesearch['timerange_hour'],livesearch['timerange_minute']]
       	result.write('\tTime(day:hour:min): %s\n' % time)
       	if repo_show:
       	  result.write('\tRepos: %s\n' % livesearch['repos'])
       	result.write('\t-----------------------------------------\n\n')
    result.write('\nList of Reports:\n...................................................................\n')
    for report in db.reportdesign.find({'user':user['username']}):
      schedule=report['schedule']
      if 'interval' in schedule.keys():
        if schedule['interval']:
          result.write('\n ...... %s\n' % str(base64.b64decode(report['name'])))
          result.write('\t=======================================\n')
          result.write('\tRepos: %s\n' % schedule['repos'])
          result.write('\tType: %s\n' % schedule['export_type'])
          for interval in schedule['interval']:
            result.write('\tInterval: %s %s\n' % (interval['name'], interval['timeRange']))
            ui_data=report['ui_data']
            for query in ui_data['queries']:
              result.write('\n\t%s\n' % query['name'].encode("utf-8")) 
              result.write('\t-----------------------------------------\n\tQuery: %s\n' % query['query'].encode("utf-8")) 
              render=query['render']
              result.write('\tType: %s\n' % (render['type'])) 
       	      result.write('\t-----------------------------------------\n')

    result.write('\n...............................# End of User: %s #....................................\n\n' % user['username'].encode("utf-8"))

def main():
  hostname = platform.node()
  myfile = 'result_users_livesearch_info_'+hostname+'.txt'
  result = open(myfile,'w')
#  repo_show = raw_input('Show Repo Info (1 for YES; 0 for NO):')
#  query_show = raw_input('Show Livesearch Query Info (1 for YES; 0 for NO):')
#  get_user_activity(result,int(repo_show),int(query_show))
  get_user_activity(result,True,True)


if __name__ == "__main__":
    main()



