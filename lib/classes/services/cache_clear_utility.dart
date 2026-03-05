// Add this to your settings page or debug menu

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:picturo_app/cubits/get_sub_topics_list/get_sub_topics_list_cubit.dart';
import 'package:picturo_app/utils/common_file.dart';

class CacheClearButton extends StatefulWidget {
  const CacheClearButton({Key? key}) : super(key: key);

  @override
  State<CacheClearButton> createState() => _CacheClearButtonState();
}

class _CacheClearButtonState extends State<CacheClearButton> {
  bool _isClearing = false;

  Future<void> _clearAllCache() async {
    setState(() => _isClearing = true);
    
    try {
      await LocalStorageHelper.clearAllQuestionsCache();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All cached data cleared successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error clearing cache: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(left: 5,right: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(16))
            ),
            child: ListTile(
              tileColor: Colors.white,
              leading: Icon(
                CupertinoIcons.trash_fill,
                color: Colors.red,
              ),
              title: Text('Clear App Cache',style: TextStyle(fontFamily: AppConstants.commonFont,),),
              subtitle: Text('Clear all downloaded images and cached data', maxLines: 1,overflow: TextOverflow.ellipsis,),
              trailing: _isClearing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _isClearing ? null : () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Colors.white,
                    title: Text('Clear Cache?',style: TextStyle(fontFamily: AppConstants.commonFont,fontWeight: FontWeight.bold),),
                    content: Text(
                      'This will clear all downloaded images and cached data. '
                      'Content will be downloaded again when you view it.',
                      style: TextStyle(fontFamily: AppConstants.commonFont,),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel',style: TextStyle(fontFamily: AppConstants.commonFont,),),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearAllCache();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Text('Clear Cache',style: TextStyle(fontFamily: AppConstants.commonFont,color: Colors.white),),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}