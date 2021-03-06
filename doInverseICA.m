function [EEG] = doInverseICA(EEG)

    global message1
    global f1
    global f2
    global f3
    global f4
    global fig
    
    % compute activations (they are not computed automatically) - this 
    %W = weight*sphere;    % EEGLAB --> W unmixing matrix
    %icaEEG = W*Data;      % EEGLAB --> U = W.X activations    % MORE INFO
    % We plot EEG.icawinv (W-1) as these are the weights for the topographies,
    % - the inverse of the unmixing matrix W
    %see: http://www.mat.ucm.es/~vmakarov/Supplementary/wICAexample/TestExample.html
    %see; http://arnauddelorme.com/ica_for_dummies/
    if size(EEG.icaact,1) == 0
        EEG.icaact = (EEG.icaweights*EEG.icasphere)*EEG.data(EEG.icachansind,:);
    end

    % command to run ICA via EEGLAB (already implemented in preprocess data)
    %EEG = pop_runica(EEG, 'extended',1);

    % amount of data to visualize
    EEG.icaT1 = 1;
    EEG.icaT2 = 5*EEG.srate;
    EEG.allComponents = EEG.icachansind;
    EEG.selectedComponents = 1;
    EEG.icaChannel = 1;
    scales = [(EEG.srate/10) (EEG.srate/5) (EEG.srate/2) (EEG.srate) (EEG.srate*2) (EEG.srate*5) (EEG.srate*10)];
    scalesCounter = 4;
    EEG.currentScale = EEG.srate;
    EEG.saveICA = 0;

    scrsz = get(groot,'ScreenSize');

    fig = figure;
    set(fig,'KeyPressFcn',@keyboardFun);
    Left = 100;
    LeftSpace = 125;
    Up = 800;
    UpSpace = 35;
    
    btn1 = uicontrol('Style','pushbutton', 'String', 'Quit','Position',[Left Up 100 20],'Callback',@quitLoop);
    btn1.BackgroundColor = 'w';
    btn2 = uicontrol('Style','togglebutton', 'String', 'Save Data','Position',[Left Up-UpSpace 100 20],'Callback',@saveData);
    btn2.BackgroundColor = 'w';
    btn4 = uicontrol('Style','pushbutton', 'String', 'Set Time Range','Position',[Left Up-2*UpSpace 100 20],'Callback',@setTimeWindow);
    btn4.BackgroundColor = 'w';
    btn3 = uicontrol('Style', 'listbox','Position',[Left + 1*LeftSpace Up-3*UpSpace 100 100],'string',EEG.allComponents,'Max',max(EEG.allComponents),'Min',1,'Callback',@selectComponents);
    btn3.BackgroundColor = 'w';
    btn5 = uicontrol('Style', 'popup','String', {EEG.chanlocs.labels},'Position',[Left Up-5.2*UpSpace 100 100],'Callback', @setICAChannel);
    btn5.Value = 35;
    btn5.BackgroundColor = 'w';
    
    % component numbers
    txt1 = uicontrol('Style','text','Position',[Left+2*LeftSpace Up-UpSpace 100 20],'String',message1,'HorizontalAlignment','left');
    txt1.BackgroundColor = 'w';
    txt2 = uicontrol('Style','text','Position',[Left+2*LeftSpace Up 200 20],'String','Selected Components','HorizontalAlignment','left');
    txt2.BackgroundColor = 'w';
    txt6 = uicontrol('Style','text','Position',[Left+1*LeftSpace Up 110 20],'String','Select Components','HorizontalAlignment','left');
    txt6.BackgroundColor = 'w';
    txt7 = uicontrol('Style','text','Position',[Left+4*LeftSpace Up 400 20],'String','Use left and right arrow keys to scroll','HorizontalAlignment','left');
    txt7.BackgroundColor = 'w';
    txt8 = uicontrol('Style','text','Position',[Left+4*LeftSpace Up-UpSpace 400 20],'String','Use up and down arrow keys to change vertical scale','HorizontalAlignment','left');
    txt8.BackgroundColor = 'w';
    txt9 = uicontrol('Style','text','Position',[Left+4*LeftSpace Up-2*UpSpace 400 20],'String','Use s to change horizontal scale','HorizontalAlignment','left');
    txt9.BackgroundColor = 'w';
    
    [EEG] = redoMath(EEG);
    [EEG] = plotComponentLoadings(EEG);
    
    function [EEG] = redoMath(EEG)
        
        icaTempAcct = [];
        icaTempAcct = EEG.icaact;                           % replicate the activations
        icaTempAcct(EEG.selectedComponents,:) = 0;          % suppress artifacts
        EEG.reconstructedEEG = EEG.icawinv*icaTempAcct;     % rebuild data

    end

    function [EEG] = plotComponentLoadings(EEG)
        
        figure(fig);
        
        delete(f2);
        delete(f3);
        delete(f4);
        
        f2 = subplot_tight(2,2,2);
        
        topoData = EEG.selectedComponents(1);
        topoplot(EEG.icawinv(:,topoData), EEG.chanlocs, 'verbose','off','style','fill','chaninfo',EEG.chaninfo,'numcontour',8);
        title(['Component ' num2str(topoData)]);

        f3 = subplot_tight(2,2,3);
        
        timeData = [];
        timeData = EEG.icaT1:1:EEG.icaT2;
        eegData = [];
        eegData = squeeze(EEG.data(EEG.icaChannel,EEG.icaT1:EEG.icaT2));
        icaData = [];
        plot(timeData,eegData);
        title('EEG Data (BLUE) compared to ICA Component Activation (RED)');
        hold on;
        if length(EEG.selectedComponents) > 0
            icaData = EEG.icaact(EEG.selectedComponents,EEG.icaT1:EEG.icaT2);
            icaData = sum(icaData,1);
        else
            icaData(EEG.icaT1:EEG.icaT2) = 0;
        end
        plot(timeData,icaData);        
        [crossCor,lag] = xcorr(icaData,eegData,0,'coeff');
        xlabel(['Cross Correlation: ' num2str(crossCor)]);
        EEG.icaCrossCor = crossCor;
        hold off;
        
        f4 = subplot_tight(2,2,4);
        reconstructPlotData = squeeze(EEG.reconstructedEEG(EEG.icaChannel,EEG.icaT1:EEG.icaT2));
        plot(timeData,eegData);
        xlabel('EEG Data (BLUE) compared to Reconstructed EEG Data (RED)');
        hold on;
        if sum(icaData) ~= 0
            plot(timeData,reconstructPlotData);
        end
        hold off;
        
    end

    function saveData(source,event)
        
        button_state = get(source,'Value');
        
        if button_state == get(source,'Max')
            
            EEG.saveICA = 1;
            
            [EEG] = redoMath(EEG);
            [EEG] = plotComponentLoadings(EEG);

            uiwait(msgbox('ICA transformed data will be saved','DONE!!!','modal'));        
        
        elseif button_state == get(source,'Min')

            EEG.saveICA = 0;
            
            [EEG] = redoMath(EEG);
            [EEG] = plotComponentLoadings(EEG);

            uiwait(msgbox('ICA transformed data will not be saved','DONE!!!','modal'));             
            
        end
        
    end

    function setTimeWindow(source,event)
        
        prompt = {'Enter the start data point','Enter the end data point'};
        dlg_title = 'Set ICA Time Window';
        num_lines = 2;
        defaultans = {'1','10000'};
        answer{1} = 0;
        answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
        
        if answer{1} ~= 0
            EEG.icaT1 = str2num(answer{1});
            EEG.icaT2 = str2num(answer{2});
            [EEG] = redoMath(EEG);
            [EEG] = plotComponentLoadings(EEG);
        end

    end

    function quitLoop(source,event)

        close all;

    end

    function selectComponents(source,event)
    
        EEG.selectedComponents = get(source,'value');
        testString = [];
        for counter = 1:length(EEG.selectedComponents)
            newBit = [num2str(EEG.selectedComponents(counter)) ' '];
            testString = [testString newBit];
        end
        
        message1 = [testString];
        set(txt1, 'String', message1);
        
        [EEG] = redoMath(EEG);
        [EEG] = plotComponentLoadings(EEG);

    end

    function setICAChannel(source,event)
    
        EEG.icaChannel = source.Value;
      
        [EEG] = redoMath(EEG);
        [EEG] = plotComponentLoadings(EEG);

    end

    function keyboardFun(source,event)
        
        if strcmp(event.Key,'rightarrow')
            EEG.icaT1 = EEG.icaT1 + EEG.currentScale;
            EEG.icaT2 = EEG.icaT2 + EEG.currentScale;
            
            if EEG.icaT2 > size(EEG.data,2)
                EEG.icaT1 = 1;
                EEG.icaT2 = EEG.currentScale;
            end
        end
        if strcmp(event.Key,'leftarrow')
            EEG.icaT1 = EEG.icaT1 - EEG.currentScale;
            EEG.icaT2 = EEG.icaT2 - EEG.currentScale;
            
            if EEG.icaT1 < 1
                EEG.icaT1 = size(EEG.data,2) - EEG.currentScale;
                EEG.icaT2 = size(EEG.data,2);
            end
        end
        if strcmp(event.Key,'uparrow')
            if EEG.icaChannel < size(EEG.data,1)
                EEG.icaChannel = EEG.icaChannel + 1;
            end
        end
        if strcmp(event.Key,'downarrow')
            if EEG.icaChannel > 1
                EEG.icaChannel = EEG.icaChannel - 1;
            end
        end        
        if strcmp(event.Key,'s')       
            scalesCounter = scalesCounter + 1;
            if scalesCounter > length(scales)
                scalesCounter = 1;
                EEG.icaT2 = EEG.icaT1 + EEG.currentScale;
            else
                EEG.currentScale = scales(scalesCounter);
                EEG.icaT2 = EEG.icaT1 + EEG.currentScale;
            end
        end
        [EEG] = redoMath(EEG);
        [EEG] = plotComponentLoadings(EEG);
        
    end
    
end