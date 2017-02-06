% pop_loadeep_v4() - Load an EEProbe continuous file (*.cnt).
%                 (pop out window if no arguments)
%
% Usage:
%   >> [EEG] = pop_loadeep_v4;
%   >> [EEG] = pop_loadeep_v4( filename, 'key', 'val', ...);
%
% Graphic interface:
%
%   "Time interval in seconds" - [edit box] specify time interval [min max]
%                                to import portion of data. Command line equivalent
%                                in loadeep: 'time1' and 'time2'
%   "Import triggers "         - [checkbox] set this option to import triggers from the
%                                trigger file (*.trg). Command line equivalent 'triggerfile'.
% Inputs:
%   filename                   - file name
%
% Optional inputs:
%   'triggerfile'               -'on' or 'off' (default = 'off')
%   Same as loadeep() function.
%
% Outputs:
%   [EEG]                       - EEGLAB data structure
%
% Note:
% This script is based on pop_loadcnt.m to make it compatible and easy to use in
% EEGLab.
%
% Author: Robert Smies, ANT Neuro B.V., Enschede, The Netherlands, 2017-02-06
%
% See also: eeglab(), loadeep()
%

%123456789012345678901234567890123456789012345678901234567890123456789012

% Copyright (C) 2017 Robert Smies, rsmies@ant-neuro.com
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% Revision 1.0  2017-02-06, 14:12:13 rsmies
% Initial: create new importer based on the v4 libeep functions
%
% Advanced Neuro Technology (ANT) BV, The Netherlands, www.ant-neuro.com / info@ant-neuro.com
%

function [EEG, command]=pop_loadeep_v4(filename, varargin);

command = '';
filepath = '';
EEG=[];

if nargin < 1

	% ask user
	[filename, filepath] = uigetfile('*.CNT;*.cnt', 'Choose an EEProbe continuous file -- pop_loadeep_v4()');
    drawnow;
	if filename == 0 return; end;

	% popup window parameters
	% -----------------------
    uigeom     = { [1 0.5] [1.09 0.13 0.4]};
    uilist   = { { 'style' 'text' 'string' 'Time interval in s (i.e. [0 100];' } ...
                 { 'style' 'edit' 'string' '' } {} };

	result = inputgui(uigeom, uilist, 'pophelp(''pop_loadeep_v4'')', 'Load an EEProbe dataset');
	if length( result ) == 0 return; end;

	% decode parameters
	% -----------------
    options = [];
    if ~isempty(result{1}),
        timer =  eval( [ '[' result{1} ']' ]);
        options = [ options ', ''time1'', ' num2str(timer(1)) ', ''time2'', ' num2str(timer(2)) ];
    end;
else
	options = vararg2str(varargin);
end;

% variable arguments to struct
if ~isempty(varargin)
	 r = struct(varargin{:});
else r = [];
end;

% load datas
% ----------
EEG = eeg_emptyset;
if exist('filepath')
	fullFileName = sprintf('%s%s', filepath, filename);
else
	fullFileName = filename;
end;

% read file info
r.v4_info = eepv4_read_info(fullFileName);
if ~isfield(r, 'sample1')
  if isfield(r, 'time1')
    r.sample1 = 1 + r.time1 * r.v4_info.sample_rate;
  else
    r.sample1 = 1;
  end;
end;
if ~isfield(r, 'sample2')
  if isfield(r, 'time2')
    r.sample2 = 1 + r.time2 * r.v4_info.sample_rate;
  else
    r.sample2 = r.v4_info.sample_count;
  end;
end;

% read data
r.v4_data = eepv4_read(fullFileName, r.sample1, r.sample2)

EEG.data            = r.v4_data.samples;
EEG.comments        = [ 'Original file: ' fullfile(filepath, filename) ];
EEG.setname         = 'EEProbe continuous data';
EEG.nbchan          = r.v4_info.channel_count;
EEG.xmin            = r.v4_data.start_in_seconds;
EEG.srate           = r.v4_info.sample_rate;
EEG.pnts            = 1 + r.sample2 - r.sample1;
% Create struct for holding channel labels
for i=1:r.v4_info.channel_count
    chanlocs(i).labels=r.v4_info.channels(i).label;
    chanlocs(i).theta=0;
    chanlocs(i).radius=0;
    chanlocs(i).X=0;
    chanlocs(i).Y=0;
    chanlocs(i).Z=0;
    chanlocs(i).sph_theta=0;
    chanlocs(i).sph_phi=0;
    chanlocs(i).sph_radius=0;
end
EEG.chanlocs=chanlocs;
% Create struct for holding triggers
for i=1:size(r.v4_data.triggers, 2)
    event(i).type = r.v4_data.triggers(i).label;
    event(i).latency = 1 + r.v4_data.triggers(i).offset_in_segment;
end;
EEG.event=event;

EEG = eeg_checkset(EEG);

if length(options) > 2
    command = sprintf('EEG = pop_loadeep_v4(''%s'' %s);',fullFileName, options);
else
    command = sprintf('EEG = pop_loadeep_v4(''%s'');',fullFileName);
end;
return;
