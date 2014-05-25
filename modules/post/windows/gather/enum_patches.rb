##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##


require 'msf/core'
require 'msf/core/post/common'

class Metasploit3 < Msf::Post
  include Msf::Post::Common

  def initialize(info={})
    super(update_info(info,
      'Name'            => "Windows Enumerate Applied Patches",
      'Description'     => %q{
          This module will attempt to enumerate which patches are applied to a windows system
          based on the result of the WMI query: SELECT HotFixID FROM Win32_QuickFixEngineering
        },
      'License'         => MSF_LICENSE,
      'Platform'        => ['win'],
      'SessionTypes'    => ['meterpreter'],
      'Author'          => [
          'zeroSteiner', # Original idea
          'mubix' # Post module
        ]
    ))

    register_options(
      [
        OptBool.new('MSFLOCALS', [ false, 'Search for missing patchs for which there is a MSF local module', true]),
        OptString.new('KB',  [ true, 'A comma separated list of KB patches to search for', 'KB2871997, KB2928120'])
      ], self.class)
  end

  # The sauce starts here
  def run
    patches = []
    msfmodules = [
      'KB977165',   # MS10-015 kitrap0d
      'KB2305420',  # MS10-092 schelevator
      'KB2592799',  # MS11-080 afdjoinleaf
      'KB2778930',  # MS13-005 hwnd_broadcast
      'KB2850851',  # MS13-053 schlamperei
      'KB2870008'   # MS13-081 track_popup_menu
    ]

    datastore['KB'].split(',').each do |kb|
      patches << kb.strip
    end

    if datastore['MSFLOCALS']
      patches = patches + msfmodules
    end

    client.core.use("extapi") if not client.ext.aliases.include?("extapi")
    begin
      objects = client.extapi.wmi.query("SELECT HotFixID FROM Win32_QuickFixEngineering")
    rescue RuntimeError
      print_error "Known bug in WMI query, try migrating to another process"
      return
    end
    kb_ids = objects[:values].map { |kb| kb[0] }
    patches.each do |kb|
      if kb_ids.include?(kb)
        print_status("#{kb} applied")
      else
        case kb
        when "KB977165"
          print_good("KB977165 - Possibly vulnerable to MS10-015 kitrap0d if Windows 2K SP4 - Windows 7 (x86)")
        when "KB2305420"
          print_good("KB2305420 - Possibly vulnerable to MS10-092 schelevator if Vista, 7, and 2008")
        when "KB2592799"
          print_good("KB2592799 - Possibly vulnerable to MS11-080 afdjoinleaf if XP SP2/SP3 Win 2k3 SP2")
        when "KB2778930"
          print_good("KB2778930 - Possibly vulnerable to MS13-005 hwnd_broadcast, elevates from Low to Medium integrity")
        when "KB2850851"
          print_good("KB2850851 - Possibly vulnerable to MS13-053 schlamperei if x86 Win7 SP0/SP1")
        when "KB2870008"
          print_good("KB2870008 - Possibly vulnerable to MS13-081 track_popup_menu")
        else
          print_good("#{kb} is missing")
        end
      end
    end
  end
end
