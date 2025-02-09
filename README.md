# ZHAudioRecord

Simple audio recording with audio spectrum, similar to WeChat

##How to use
```objective-c

- (void)viewDidLoad {
    [super viewDidLoad];
    ZHAudioRecord.record.delegate = self;   
}

- (void)gestureAction:(UILongPressGestureRecognizer *)gesture{
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"example"];
    
    CGPoint point = [gesture locationInView:self.view];
    [ZHAudioRecord.record.displayView upgradeGesturePoint:point];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [ZHAudioRecord.record startRecordWithFilePath:filePath];
        return;
    }
    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        [ZHAudioRecord.record stopRecord];
    }
}

#pragma mark - ZHAudioRecordDelegate

- (void)audioRecord:(ZHAudioRecord *)record didFinishRecordWithUrlPath:(NSString *)urlPath status:(ZHRecordFinishStatus)status{
        
}

- (void)audioRecord:(ZHAudioRecord *)record didErrored:(NSError *)error{

}

```
